esphome:
  name: fan-douche
  on_boot:
      priority: -100 #lowest priority so start last
      then:
       - lambda: id(pwm_output_fan).turn_off(); #turn off the fan at boot time
       
esp32:
  board: esp32dev
  framework:
    type: arduino

# Enable logging
logger:

# Enable Home Assistant API
api:

ota:
  password: "ab67a449282a6ef757989712fc41f38d"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Fan-Douche Fallback Hotspot"
    password: "vDyC1qPOWl95"

captive_portal:
    
# Add virtual switch to remotely restart the ESP via HA
# https://esphome.io/components/switch/restart
button:
  - platform: restart
    name: "ESP_fan-douche restart"

#https://esphome.io/components/fan/speed.html
output:
#control the PWM fan
  - platform: ledc
    pin: GPIO25
    frequency: 1000 Hz
    id: pwm_output_fan
#Control the LED
  - platform: ledc
    pin: GPIO13
    frequency: 1000 Hz
    id: LEDs

fan:
  - platform: speed
    output: pwm_output_fan
    name: "Ventilator-Douche"


#Control the RGB led RED
light:
  - platform: monochromatic
    output: LEDs
    name: "Ventilator-Douche-LEDs"

#https://esphome.io/components/sensor/pulse_counter.html
#Get the RPM of one fan
sensor:
  - platform: pulse_counter
    pin: GPIO26
    name: "Ventilator-Douche-RPM"
    update_interval: 35s
    unit_of_measurement: 'RPM'
    filters:
      - multiply: 0.5 #fan runs according to specs 3500rpm, so need to convert the received pulses as that was max 8000

  - platform: dht
    pin: GPIO27
    temperature:
      name: "TH13_Ventilator-Douche-Temperature"
      id: th13_temp
    humidity:
      name: "TH13_Ventilator-Douche-Humidity"
      id: th13_humidity
    model: AM2302
    update_interval: 30s



#Get value from Helper in Home Assistant
#https://esphome.io/components/binary_sensor/homeassistant.html
binary_sensor:
  - platform: homeassistant
    id: override_from_home_assistant_helper
    entity_id: input_boolean.ventilator_douche_override


#logic:
time:
  - platform: homeassistant
    id: homeassistant_time

    on_time:
      - seconds: /30  # needs to be set, otherwise every second this is triggered!
        minutes: '*'  # Trigger every 0.5 minute
        then:
          lambda: !lambda |-
            auto time = id(homeassistant_time).now();
            int t_now = parse_number<int>(id(homeassistant_time).now().strftime("%H%M")).value();
            float temp_measured = static_cast<int>(id(th13_temp).state);
            float humidity_measured = static_cast<int>(id(th13_humidity).state);
            if (id(override_from_home_assistant_helper).state)
              {
                //Do nothing as the override is active which is set in Home Assistant
              }
              else
              {
                  if (((temp_measured) >= 35) || ((humidity_measured) >= 85))
                  {
                    id(pwm_output_fan).set_level(1); //set the speed level between 0 and 1 https://esphome.io/components/output/index.html
                  }
                  else
                  {
                    if (((humidity_measured) >=70) && ((humidity_measured) < 85))
                    {
                      id(pwm_output_fan).set_level(0.5); 
                    }
                    else
                    {
                        if ((humidity_measured) <= 69)
                        {
                          id(pwm_output_fan).turn_off();  
                        }
                    } 
                  }
              }




