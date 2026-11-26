#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ER_GNSS_LINE_MAX 128

typedef struct {
    bool fix_valid;
    double latitude_deg;
    double longitude_deg;
    double speed_kph;
    double course_deg;
    uint8_t satellites;
    double hdop;
    char utc_time[11]; /* hhmmss.sss, empty when unavailable */
    char utc_date[7]; /* ddmmyy, empty when unavailable */
    int64_t received_monotonic_us;
    uint32_t valid_rmc_count;
    uint32_t valid_gga_count;
    uint32_t checksum_error_count;
    uint32_t malformed_count;
} er_gnss_snapshot_t;

/* Feed one complete NMEA sentence, including its checksum and line ending. */
bool er_gnss_parser_feed(const char *sentence, size_t length,
                         int64_t received_monotonic_us);
void er_gnss_parser_get_snapshot(er_gnss_snapshot_t *snapshot);
void er_gnss_parser_reset(void);

#ifdef __cplusplus
}
#endif
