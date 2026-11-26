#include "event_uploader.h"
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "cJSON.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_random.h"
#include "event_journal.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define RESPONSE_MAX 4096
#define REQUEST_TIMEOUT_MS 15000
#define BACKOFF_MIN_MS 2000
#define BACKOFF_MAX_MS 300000
static const char *TAG="er_event_uploader";
static char s_endpoint[256];
static char s_token[160];
static char *s_root_ca;
static bool s_started;
typedef struct { char data[RESPONSE_MAX+1]; size_t length; bool overflow; } response_t;

static const char *type_name(er_event_type_t v) {
 switch(v) {
 case ER_EVENT_BOOT:return "BOOT"; case ER_EVENT_TRIP_STARTED:return "TRIP_STARTED";
 case ER_EVENT_TRIP_ENDED:return "TRIP_ENDED";
 case ER_EVENT_STUDENT_BOARDING_MATCHED:return "STUDENT_BOARDING_MATCHED";
 case ER_EVENT_STUDENT_BOARDING_UNCERTAIN:return "STUDENT_BOARDING_UNCERTAIN";
 case ER_EVENT_STUDENT_BOARDING_UNMATCHED:return "STUDENT_BOARDING_UNMATCHED";
 case ER_EVENT_DRIVER_PICKUP_CONFIRMED:return "DRIVER_PICKUP_CONFIRMED";
 case ER_EVENT_DRIVER_NEXT_STOP:return "DRIVER_NEXT_STOP";
 case ER_EVENT_DEVICE_HEALTH:return "DEVICE_HEALTH"; case ER_EVENT_DEVICE_FAULT:return "DEVICE_FAULT";
 default:return NULL;
 }}
static const char *variant_name(er_device_variant_t v) {
 return v==ER_DEVICE_VARIANT_VISION_GPS?"vision_gps":v==ER_DEVICE_VARIANT_GPS_ONLY?"gps_only":NULL;
}
static const char *quality_name(er_time_quality_t v) {
 switch(v){case ER_TIME_UNSYNCED:return "UNSYNCED";case ER_TIME_RTC:return "RTC";case ER_TIME_GNSS:return "GNSS";case ER_TIME_NETWORK:return "NETWORK";default:return NULL;}
}
static esp_err_t serialize_event(const er_event_record_t *e,char **out) {
 if(!e||!out)return ESP_ERR_INVALID_ARG;
 const char *type=type_name(e->type),*variant=variant_name(e->variant),*quality=quality_name(e->time_quality);
 if(!type||!variant||!quality||e->event_id[32]!='\0'||!e->device_id[0])return ESP_ERR_INVALID_ARG;
 cJSON *root=cJSON_CreateObject(),*events=cJSON_CreateArray(),*item=cJSON_CreateObject();
 if(!root||!events||!item){cJSON_Delete(root);cJSON_Delete(events);cJSON_Delete(item);return ESP_ERR_NO_MEM;}
 cJSON_AddNumberToObject(root,"schema_version",1);
 cJSON_AddNumberToObject(item,"schema_version",1);
 cJSON_AddStringToObject(item,"event_id",e->event_id);
 cJSON_AddStringToObject(item,"device_id",e->device_id);
 char seq[21],mono[21];
 snprintf(seq,sizeof(seq),"%" PRIu64,e->sequence);
 snprintf(mono,sizeof(mono),"%" PRIi64,e->monotonic_time_us>=0?e->monotonic_time_us:0);
 cJSON_AddStringToObject(item,"device_sequence",seq);
 cJSON_AddStringToObject(item,"event_type",type);
 if(e->trip_id[0])cJSON_AddStringToObject(item,"trip_id",e->trip_id);else cJSON_AddNullToObject(item,"trip_id");
 if(e->utc_time_ms>0&&e->time_quality!=ER_TIME_UNSYNCED){
  time_t sec=(time_t)(e->utc_time_ms/1000);struct tm utc={0};char stamp[32],iso[40];
  if(!gmtime_r(&sec,&utc)||!strftime(stamp,sizeof(stamp),"%Y-%m-%dT%H:%M:%S",&utc)){cJSON_Delete(root);cJSON_Delete(events);cJSON_Delete(item);return ESP_ERR_INVALID_ARG;}
  snprintf(iso,sizeof(iso),"%s.%03" PRIu64 "Z",stamp,(uint64_t)(e->utc_time_ms%1000));
  cJSON_AddStringToObject(item,"event_time_utc",iso);
 }else cJSON_AddNullToObject(item,"event_time_utc");
 cJSON_AddStringToObject(item,"monotonic_time_us",mono);
 cJSON_AddStringToObject(item,"time_quality",quality);
 cJSON_AddStringToObject(item,"firmware_version",e->firmware_version);
 cJSON_AddStringToObject(item,"hardware_revision",e->hardware_revision);
 cJSON_AddStringToObject(item,"variant",variant);
 cJSON *payload=e->payload[0]?cJSON_Parse(e->payload):cJSON_CreateObject();
 if(!payload||!cJSON_IsObject(payload)){cJSON_Delete(payload);cJSON_Delete(root);cJSON_Delete(events);cJSON_Delete(item);return ESP_ERR_INVALID_ARG;}
 char *ptext=cJSON_PrintUnformatted(payload);cJSON_Delete(payload);
 if(!ptext||strlen(ptext)>192){cJSON_free(ptext);cJSON_Delete(root);cJSON_Delete(events);cJSON_Delete(item);return ESP_ERR_INVALID_SIZE;}
 cJSON *pcopy=cJSON_Parse(ptext);cJSON_free(ptext);
 if(!pcopy){cJSON_Delete(root);cJSON_Delete(events);cJSON_Delete(item);return ESP_ERR_NO_MEM;}
 cJSON_AddItemToObject(item,"payload",pcopy);
 cJSON_AddItemToArray(events,item);cJSON_AddItemToObject(root,"events",events);
 char *serialized=cJSON_PrintUnformatted(root);cJSON_Delete(root);
 if(!serialized)return ESP_ERR_NO_MEM;*out=serialized;return ESP_OK;
}
static esp_err_t on_http_event(esp_http_client_event_t *ev) {
 response_t *r=(response_t*)ev->user_data;
 if(ev->event_id==HTTP_EVENT_ON_DATA&&ev->data_len>0){
  if(!r||(size_t)ev->data_len>RESPONSE_MAX-r->length){if(r)r->overflow=true;return ESP_FAIL;}
  memcpy(r->data+r->length,ev->data,(size_t)ev->data_len);r->length+=(size_t)ev->data_len;r->data[r->length]='\0';
 }return ESP_OK;
}
static bool has_id(const cJSON *a,const char *id) {
 if(!cJSON_IsArray(a))return false;const cJSON *v=NULL;
 cJSON_ArrayForEach(v,a)if(cJSON_IsString(v)&&v->valuestring&&strcmp(v->valuestring,id)==0)return true;
 return false;
}
static esp_err_t upload_one(const er_event_record_t *record) {
 char *body=NULL;esp_err_t err=serialize_event(record,&body);if(err!=ESP_OK)return err;
 response_t response={0};
 esp_http_client_config_t cfg={.url=s_endpoint,.method=HTTP_METHOD_POST,.timeout_ms=REQUEST_TIMEOUT_MS,.cert_pem=s_root_ca,.event_handler=on_http_event,.user_data=&response,.buffer_size=2048,.buffer_size_tx=2048,.keep_alive_enable=false};
 esp_http_client_handle_t client=esp_http_client_init(&cfg);
 if(!client){cJSON_free(body);return ESP_ERR_NO_MEM;}
 err=esp_http_client_set_header(client,"Content-Type","application/json");
 if(err==ESP_OK)err=esp_http_client_set_header(client,"X-Device-Token",s_token);
 if(err==ESP_OK)err=esp_http_client_set_post_field(client,body,(int)strlen(body));
 if(err==ESP_OK)err=esp_http_client_perform(client);
 int status=esp_http_client_get_status_code(client);esp_http_client_cleanup(client);cJSON_free(body);
 if(err!=ESP_OK)return err;if(response.overflow)return ESP_ERR_INVALID_SIZE;
 if(status!=202){ESP_LOGW(TAG,"Backend HTTP %d; event retained",status);return status==400||status==401||status==403||status==413?ESP_ERR_INVALID_RESPONSE:ESP_FAIL;}
 cJSON *json=cJSON_Parse(response.data);if(!json)return ESP_ERR_INVALID_RESPONSE;
 bool ack=has_id(cJSON_GetObjectItemCaseSensitive(json,"acknowledged"),record->event_id)||has_id(cJSON_GetObjectItemCaseSensitive(json,"duplicates"),record->event_id);
 cJSON_Delete(json);if(!ack)return ESP_ERR_INVALID_RESPONSE;
 err=er_event_journal_ack(record->event_id);if(err==ESP_OK)ESP_LOGI(TAG,"Acknowledged event sequence=%" PRIu64,record->sequence);return err;
}
static void sync_task(void *arg) {
 (void)arg;uint32_t backoff=BACKOFF_MIN_MS;
 for(;;){er_event_record_t e;esp_err_t err=er_event_journal_peek(&e);
  if(err==ESP_ERR_NOT_FOUND){backoff=BACKOFF_MIN_MS;vTaskDelay(pdMS_TO_TICKS(5000));continue;}
  if(err==ESP_OK)err=upload_one(&e);
  if(err==ESP_OK){backoff=BACKOFF_MIN_MS;continue;}
  uint32_t delay=backoff+esp_random()%(backoff/4U+1U);
  ESP_LOGW(TAG,"Sync deferred (%s); retry in %u ms",esp_err_to_name(err),(unsigned)delay);
  vTaskDelay(pdMS_TO_TICKS(delay));
  backoff=backoff<BACKOFF_MAX_MS/2U?backoff*2U:BACKOFF_MAX_MS;
 }}
esp_err_t er_event_uploader_start(const er_event_uploader_config_t *cfg) {
 if(!cfg||!cfg->endpoint_url||!cfg->device_token||!cfg->server_root_ca_pem||
  strncmp(cfg->endpoint_url,"https://",8)!=0||!strstr(cfg->endpoint_url,"/api/device/events")||
  strlen(cfg->endpoint_url)>=sizeof(s_endpoint)||strlen(cfg->device_token)<32||
  strlen(cfg->device_token)>=sizeof(s_token)||strlen(cfg->server_root_ca_pem)<100)return ESP_ERR_INVALID_ARG;
 if(s_started)return ESP_ERR_INVALID_STATE;
 snprintf(s_endpoint,sizeof(s_endpoint),"%s",cfg->endpoint_url);
 snprintf(s_token,sizeof(s_token),"%s",cfg->device_token);
 s_root_ca=strdup(cfg->server_root_ca_pem);if(!s_root_ca){memset(s_token,0,sizeof(s_token));return ESP_ERR_NO_MEM;}
 if(xTaskCreate(sync_task,"er_event_sync",7168,NULL,4,NULL)!=pdPASS){memset(s_token,0,sizeof(s_token));free(s_root_ca);s_root_ca=NULL;return ESP_ERR_NO_MEM;}
 s_started=true;ESP_LOGI(TAG,"Secure event sync worker started");return ESP_OK;
}
