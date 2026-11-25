idf_component_register(
    SRCS "app_main.c" "system_state.c" "driver_ui.c"
    INCLUDE_DIRS "."
    REQUIRES driver esp_timer
)
