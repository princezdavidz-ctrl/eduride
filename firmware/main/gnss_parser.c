#include "gnss_parser.h"

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include <stdlib.h>
#include <string.h>

#define ER_KNOTS_TO_KPH 1.852

static er_gnss_snapshot_t s_snapshot;
static SemaphoreHandle_t s_parser_mutex;
static bool s_rmc_active;
static bool s_gga_fix;
static char s_gga_time[11];
static double s_rmc_lat, s_rmc_lon, s_gga_lat, s_gga_lon;

static bool parse_number(const char *text, double *out)
{
    if (text == NULL || *text == '\0') return false;
    char *end = NULL;
    double value = strtod(text, &end);
    if (end == text || *end != '\0') return false;
    *out = value;
    return true;
}

static bool parse_coordinate(const char *value, const char *hemisphere,
                             bool latitude, double *degrees)
{
    double raw;
    if (!parse_number(value, &raw) || hemisphere == NULL ||
        (latitude ? raw < 0.0 || raw > 9000.0 : raw < 0.0 || raw > 18000.0)) {
        return false;
    }
    double whole = (double)((int)(raw / 100.0));
    double minutes = raw - whole * 100.0;
    if (minutes < 0.0 || minutes >= 60.0) return false;
    double result = whole + minutes / 60.0;
    if (latitude) {
        if (result > 90.0 || (strcmp(hemisphere, "N") != 0 &&
                              strcmp(hemisphere, "S") != 0)) return false;
        if (strcmp(hemisphere, "S") == 0) result = -result;
    } else {
        if (result > 180.0 || (strcmp(hemisphere, "E") != 0 &&
                               strcmp(hemisphere, "W") != 0)) return false;
        if (strcmp(hemisphere, "W") == 0) result = -result;
    }
    *degrees = result;
    return true;
}

static bool valid_time(const char *value)
{
    if (value == NULL || strlen(value) < 6 || strlen(value) > 10) return false;
    for (size_t i = 0; i < 6; ++i) if (!isdigit((unsigned char)value[i])) return false;
    if (value[6] == '\0') return true;
    if (value[6] != '.') return false;
    for (size_t i = 7; value[i] != '\0'; ++i)
        if (!isdigit((unsigned char)value[i])) return false;
    return true;
}

static bool valid_date(const char *value)
{
    if (value == NULL || strlen(value) != 6) return false;
    for (size_t i = 0; i < 6; ++i) if (!isdigit((unsigned char)value[i])) return false;
    return true;
}

static bool parse_checksum(char *line, size_t length, char **body_end)
{
    char *star = memchr(line, '*', length);
    if (star == NULL || (size_t)(star - line) + 3 != length || star[3] != '\0') return false;
    int high = isdigit((unsigned char)star[1]) ? star[1] - '0' :
        (toupper((unsigned char)star[1]) >= 'A' && toupper((unsigned char)star[1]) <= 'F'
         ? toupper((unsigned char)star[1]) - 'A' + 10 : -1);
    int low = isdigit((unsigned char)star[2]) ? star[2] - '0' :
        (toupper((unsigned char)star[2]) >= 'A' && toupper((unsigned char)star[2]) <= 'F'
         ? toupper((unsigned char)star[2]) - 'A' + 10 : -1);
    if (high < 0 || low < 0) return false;
    unsigned char checksum = 0;
    for (char *p = line + 1; p < star; ++p) checksum ^= (unsigned char)*p;
    if (checksum != (unsigned char)((high << 4) | low)) return false;
    *body_end = star;
    return true;
}

static size_t split_fields(char *body, char *fields[], size_t capacity)
{
    size_t count = 0;
    if (capacity == 0) return 0;
    fields[count++] = body;
    for (char *p = body; *p != '\0'; ++p) {
        if (*p == ',') {
            *p = '\0';
            if (count == capacity) return count;
            fields[count++] = p + 1;
        }
    }
    return count;
}

static void refresh_fix(void)
{
    s_snapshot.fix_valid = s_rmc_active && s_gga_fix &&
        strncmp(s_snapshot.utc_time, s_gga_time, 6) == 0 &&
        fabs(s_rmc_lat - s_gga_lat) < 0.01 &&
        fabs(s_rmc_lon - s_gga_lon) < 0.01;
    if (s_snapshot.fix_valid) {
        s_snapshot.latitude_deg = s_rmc_lat;
        s_snapshot.longitude_deg = s_rmc_lon;
    }
}

static bool parser_feed_unlocked(const char *sentence, size_t length,
                                 int64_t received_monotonic_us)
{
    if (sentence == NULL || length < 10 || length >= ER_GNSS_LINE_MAX) {
        ++s_snapshot.malformed_count;
        return false;
    }
    char line[ER_GNSS_LINE_MAX];
    memcpy(line, sentence, length);
    line[length] = '\0';
    while (length > 0 && (line[length - 1] == '\r' || line[length - 1] == '\n')) line[--length] = '\0';
    if (line[0] != '$') { ++s_snapshot.malformed_count; return false; }

    char *end = NULL;
    if (!parse_checksum(line, length, &end)) {
        ++s_snapshot.checksum_error_count;
        return false;
    }
    *end = '\0';
    char *fields[20];
    size_t count = split_fields(line + 1, fields, 20);
    if (count < 10) { ++s_snapshot.malformed_count; return false; }

    const char *type = fields[0] + (strlen(fields[0]) >= 3 ? strlen(fields[0]) - 3 : 0);
    if (strcmp(type, "RMC") == 0) {
        double lat, lon, knots = 0.0, course = 0.0;
        if (!valid_time(fields[1]) || !valid_date(fields[9]) ||
            (strcmp(fields[2], "A") != 0 && strcmp(fields[2], "V") != 0) ||
            (strcmp(fields[2], "A") == 0 &&
             (!parse_coordinate(fields[3], fields[4], true, &lat) ||
              !parse_coordinate(fields[5], fields[6], false, &lon))) ||
            (fields[7][0] && !parse_number(fields[7], &knots)) ||
            (fields[8][0] && !parse_number(fields[8], &course)) ||
            knots < 0.0 || course < 0.0 || course >= 360.0) {
            s_rmc_active = false;
            refresh_fix();
            ++s_snapshot.malformed_count;
            return false;
        }
        if (strcmp(fields[2], "V") == 0) {
            s_rmc_active = false;
            s_snapshot.received_monotonic_us = received_monotonic_us;
            refresh_fix();
            return true;
        }
        s_rmc_active = true;
        s_rmc_lat = lat; s_rmc_lon = lon;
        s_snapshot.speed_kph = knots * ER_KNOTS_TO_KPH;
        s_snapshot.course_deg = course;
        (void)snprintf(s_snapshot.utc_time, sizeof(s_snapshot.utc_time), "%s", fields[1]);
        (void)snprintf(s_snapshot.utc_date, sizeof(s_snapshot.utc_date), "%s", fields[9]);
        ++s_snapshot.valid_rmc_count;
    } else if (strcmp(type, "GGA") == 0) {
        double lat, lon, quality, satellites, hdop;
        if (!valid_time(fields[1]) ||
            !parse_number(fields[6], &quality) ||
            !parse_number(fields[7], &satellites) ||
            !parse_number(fields[8], &hdop) ||
            (quality > 0.0 && (!parse_coordinate(fields[2], fields[3], true, &lat) ||
                               !parse_coordinate(fields[4], fields[5], false, &lon))) ||
            quality < 0.0 || quality > 8.0 || satellites < 0.0 || satellites > 99.0 ||
            hdop < 0.0 || hdop > 99.9) {
            ++s_snapshot.malformed_count;
            return false;
        }
        s_gga_fix = quality > 0.0;
        if (s_gga_fix) {
            s_gga_lat = lat; s_gga_lon = lon;
            (void)snprintf(s_gga_time, sizeof(s_gga_time), "%s", fields[1]);
        } else { s_gga_time[0] = '\0'; }
        s_snapshot.satellites = (uint8_t)satellites;
        s_snapshot.hdop = hdop;
        ++s_snapshot.valid_gga_count;
    } else {
        return false;
    }

    s_snapshot.received_monotonic_us = received_monotonic_us;
    refresh_fix();
    return true;
}

esp_err_t er_gnss_parser_init(void)
{
    if (s_parser_mutex != NULL) return ESP_OK;
    s_parser_mutex = xSemaphoreCreateMutex();
    return s_parser_mutex != NULL ? ESP_OK : ESP_ERR_NO_MEM;
}

bool er_gnss_parser_feed(const char *sentence, size_t length,
                         int64_t received_monotonic_us)
{
    if (s_parser_mutex == NULL || xSemaphoreTake(s_parser_mutex, portMAX_DELAY) != pdTRUE)
        return false;
    bool accepted = parser_feed_unlocked(sentence, length, received_monotonic_us);
    xSemaphoreGive(s_parser_mutex);
    return accepted;
}

void er_gnss_parser_get_snapshot(er_gnss_snapshot_t *snapshot)
{
    if (snapshot == NULL || s_parser_mutex == NULL) return;
    if (xSemaphoreTake(s_parser_mutex, portMAX_DELAY) != pdTRUE) return;
    *snapshot = s_snapshot;
    xSemaphoreGive(s_parser_mutex);
}

void er_gnss_parser_reset(void)
{
    if (s_parser_mutex == NULL || xSemaphoreTake(s_parser_mutex, portMAX_DELAY) != pdTRUE) return;
    memset(&s_snapshot, 0, sizeof(s_snapshot));
    s_rmc_active = false;
    s_gga_fix = false;
    s_rmc_lat = s_rmc_lon = s_gga_lat = s_gga_lon = 0.0;
    s_gga_time[0] = '\0';
    xSemaphoreGive(s_parser_mutex);
}
