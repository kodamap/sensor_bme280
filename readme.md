# 1. Sensor with Rasberry Pi using BME280


<!-- TOC -->

- [1. Sensor with Rasberry Pi using BME280](#1-sensor-with-rasberry-pi-using-bme280)
    - [1.1. Visualizing Sensor Data](#11-visualizing-sensor-data)
- [2. Devices and Tools](#2-devices-and-tools)
- [3. Wiring Sensor module - BME280](#3-wiring-sensor-module---bme280)
- [4. How to use](#4-how-to-use)
    - [4.1. Enable i2c interface](#41-enable-i2c-interface)
    - [4.2. Test BME280](#42-test-bme280)
    - [4.3. Script for BME280](#43-script-for-bme280)
- [5. Visualization - Grafana + Influxdb](#5-visualization---grafana--influxdb)
    - [5.1. Prerequisites](#51-prerequisites)
    - [5.2. Deploy grafana and influxdb](#52-deploy-grafana-and-influxdb)
    - [5.3. Enable Authentication in the influxdb configuration](#53-enable-authentication-in-the-influxdb-configuration)
    - [5.4. https reverse proxy using nginx (Optional)](#54-https-reverse-proxy-using-nginx-optional)
    - [5.5. deploy with docker compose](#55-deploy-with-docker-compose)
    - [5.6. Create database and user for bme280](#56-create-database-and-user-for-bme280)
    - [5.7. Data Source setting on grafana](#57-data-source-setting-on-grafana)
- [6. Send metrics to influxDB](#6-send-metrics-to-influxdb)
    - [6.1. send metrics on the docker host](#61-send-metrics-on-the-docker-host)
    - [6.2. send metrics using ssh tunnel](#62-send-metrics-using-ssh-tunnel)
- [7. grafana dashboard example](#7-grafana-dashboard-example)

<!-- /TOC -->

## 1.1. Visualizing Sensor Data

<a href="https://raw.githubusercontent.com/wiki/kodamap/sensor_bme280/images/influx_grafana_bme280.png">
<img src="https://raw.githubusercontent.com/wiki/kodamap/sensor_bme280/images/influx_grafana_bme280.png" alt="kibana dashboard" style="width:75%;height:auto;" ></a>


# 2. Devices and Tools

| devices and tools | role |
| ---  | --- |
| bme280   | Sensor module |
| Raspberry Pi Zero | IoT device |
| Grafana  | Visualizer    |
| Influxdb | Time series database |

- BME280

https://www.switch-science.com/catalog/2323/

# 3. Wiring Sensor module - BME280

| Raspberry Pi (from) | BME (To) |
| --- | --- |
| 3.3v (1pin) | Vio,CSB |
| SDA (3pin) | SDI |
| SCL 3 (5pin) | SCK |
| GROUND (9pin) | SDO,GND |

- Wiring

<a href="https://raw.githubusercontent.com/wiki/kodamap/sensor_bme280/images/bme280_pin_laytout.png">
<img src="https://raw.githubusercontent.com/wiki/kodamap/sensor_bme280/images/bme280_pin_laytout.png" alt="wiring" style="width:75%;height:auto;" ></a>

- Raspberry Pi  Pinout

<a href="https://pinout.xyz/resources/raspberry-pi-pinout.png">
<img src="https://pinout.xyz/resources/raspberry-pi-pinout.png" alt="raspberry pi pinout" style="width:75%;height:auto;" ></a>

> https://pinout.xyz/


# 4. How to use 

## 4.1. Enable i2c interface

Enable i2c interface on Razpberry Pi and reboot

```sh
$ sudo raspi-config
 > Interfacing Options  Configure connections to peripherals
   > P5 I2C Enable/Disable automatic loading of I2C kernel module
```

## 4.2. Test BME280

```sh
$ i2cdetect -y 1

     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- 76 -
```

## 4.3. Script for BME280

Clone SWITCHSCIENCE BME280 Repository

```sh
$ git clone https://github.com/SWITCHSCIENCE/BME280
```

```sh
$ python2.7 Python27/bme280_sample.py

temp : 31.17  ℃
pressure :  999.84 hPa
hum :  62.13 ％
```

# 5. Visualization - Grafana + Influxdb

## 5.1. Prerequisites

Before you can run deployment, you'll need the following installed in your local enviroment.

- docker-ce
https://docs.docker.com/install/linux/docker-ce/centos/

- docker-compose
https://docs.docker.com/compose/install/#install-compose


## 5.2. Deploy grafana and influxdb

```sh
git clone https://github.com/kodamap/sensor_bme280
```

create host storage

```sh
sudo mkdir -p /var/data/grafana ; sudo chmod 777 /var/data/grafana
sudo mkdir -p /var/data/influxdb ; sudo chmod 777 -R /var/data/influxdb
sudo mkdir -p /var/data/nginx ; sudo chmod 777 -R /var/data/nginx
```

## 5.3. Enable Authentication in the influxdb configuration

> By default, authentication is disabled in the configuration file.

https://docs.influxdata.com/influxdb/v1.6/administration/authentication_and_authorization/

```sh
$ vi sensor_bme280/dockerfiles/influxdb/influxdb.conf

[http]
  enabled = true
  bind-address = ":8086"
  auth-enabled = true # change this
  .
  .
```

```sh
$ cp sensor_bme280/dockerfiles/influxdb/influxdb.conf /var/data/influxdb/
```

## 5.4. https reverse proxy using nginx (Optional)

Set root_url for using prefix (/grafana/)

```sh
$ vi sensor_bme280/dockerfiles/grafana/grafana.ini

# The full public facing url you use in browser, used for redirects and emails
# If you use reverse proxy and sub path specify full url (with sub path)
#;root_url = http://localhost:3000
root_url = %(protocol)s://%(domain)s:%(http_port)s/grafana/
```

```sh
$ cp sensor_bme280/dockerfiles/grafana/grafana.ini /var/data/grafana/
```

Configure Nginx to work as revers proxy for grafana. Set location prefix (/grafana/)

```sh
$ vi sensor_bme280/dockerfiles/nginx/default.conf

server {
    listen 443;

    ssl_certificate /etc/nginx/conf.d/server.crt;
    ssl_certificate_key /etc/nginx/conf.d/server.key;
    ## replace this when you use lets encrypt certificate
    # ssl_certificate /etc/nginx/conf.d/fullchain.pem;
    # ssl_certificate_key /etc/nginx/conf.d/privkey.pem;

    ssl on;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    location /grafana/ {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-NginX-Proxy true;

        proxy_http_version 1.1;
        proxy_set_header Connection "";

        proxy_pass http://grafana:3000/;
        proxy_redirect off;
    }
}
```

```sh
$ cp sensor_bme280/dockerfiles/nginx/default.conf /var/data/nginx/
```

Modify the enviroment valiable "GF_SECURITY_ADMIN_PASSWORD".

```sh
$ vi sensor_bme280/dockerfiles/docker-compose.yml

  grafana:
    image: grafana/grafana:5.2.4
    build: ./grafana
    container_name: grafana
    links:
      - influxdb
    volumes:
      - "/var/data/grafana:/var/lib/grafana"
      - "/var/data/grafana/grafana.ini:/etc/grafana/grafana.ini"
    ports:
      - "3000:3000"
    logging:
      driver: "json-file"
      options:
        max-size: "10240k"
        max-file: "10"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme               # change this
```

## 5.5. deploy with docker compose

```sh
$ cd sensor_bme280/dockerfiles/
$ sudo /usr/local/bin/docker-compose up --build -d
$ sudo /usr/local/bin/docker-compose ps
  Name            Command           State           Ports
------------------------------------------------------------------
grafana    /run.sh                  Up      0.0.0.0:3000->3000/tcp
influxdb   /entrypoint.sh influxd   Up      0.0.0.0:8086->8086/tcp
nginx      /run.sh                  Up      0.0.0.0:443->443/tcp
```

You can access grafana gui

```sh
https://<your ip address>/grafana/
```

## 5.6. Create database and user for bme280

Create database(name is sensor) on docker.

```sh
$ curl -XPOST 'http://localhost:8086/query?u=admin&p=changeme' --data-urlencode 'q=CREATE DATABASE "sensor"'
{"results":[{"statement_id":0}]}

$ curl -XPOST 'http://localhost:8086/query?u=admin&p=changeme' --data-urlencode 'q=SHOW DATABASES'
{"results":[{"statement_id":0,"series":[{"name":"databases","columns":["name"],"values":[["_internal"],["sensor"]]}]}]}
```

ref: https://docs.influxdata.com/influxdb/v1.6/tools/api/

Create sensor user and grant READ/WRITE privileges to sensor user

```sh
$ cd sensor_bme280/dockerfiles/
$ sudo /usr/local/bin/docker-compose exec influxdb sh
# influx -username admin -password changeme
Connected to http://localhost:8086 version 1.4.2
InfluxDB shell version: 1.4.2
> create user sensor with PASSWORD 'password'
> show users
user   admin
----   -----
admin  true
sensor false
> grant all on sensor to sensor
> show grants for sensor
database privilege
-------- ---------
sensor   ALL PRIVILEGES
> exit
```

## 5.7. Data Source setting on grafana

Login the grafana ui 

- "Add data soruce"
- Click "Save & Test" 

Setting | Value
- | - |
Name | sensor
Type | influxDB
URL | http://influxdb:8086
Database | sensor
User | sensor
Password | password (changeme!)

Click "Save & Test" and "Data source is working"



# 6. Send metrics to influxDB

## 6.1. send metrics on the docker host

Send metrics test on the docker host

```sh
$ curl -i -XPOST "http://localhost:8086/write?db=sensor&u=sensor&p=password" --data-binary "temperature,node=localhost,location=home,unit=Celcius value=20"
HTTP/1.1 204 No Content
Content-Type: application/json
Request-Id: 6c524cf1-c60d-11e8-8026-000000000000
X-Influxdb-Build: OSS
X-Influxdb-Version: 1.4.2
X-Request-Id: 6c524cf1-c60d-11e8-8026-000000000000
Date: Tue, 02 Oct 2018 06:35:58 GMT

$ curl -XPOST 'http://localhost:8086/query?db=sensor&u=sensor&p=password' --data-urlencode 'q=select * from temperature'
{"results":[{"statement_id":0,"series":[{"name":"temperature","columns":["time","location","node","unit","value"],"values":[["2018-10-02T07:15:12.537207759Z","home","localhost","Celcius",20]]}]}]}
```

## 6.2. send metrics using ssh tunnel

You can use ssh tunnel to put data on influxdb for secure connection.
check the ip address of infuldb

```sh
$ sudo docker inspect influxdb | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.18.0.2",
```

Connect to the docker host using ssh tunnel from Raspberry Pi 

```sh
$ autossh -t -t <user>@<docker host> -p <ssh port> -L <local port of influxdb api port>:<influxdb ip address>:<remote port of influxdb api port>

# example1:
$ autossh -t -t core@172.25.250.20 -p 22 -L 38086:172.18.0.2:8086
# example2: You may want to autossh when boot (/etc/rc.local)
su - pi -s /bin/bash -c "autossh -t -t core@172.25.250.20 -p 22 -L 38086:172.18.0.2:8086"
```

Script example

- Change "PYTHON" path(example script uses pyenv for python3.x ).
ref: https://github.com/pyenv/pyenv
- I changed output in /home/pi/BME280/Python35/bme280.py specified "PY_SCRIPT" (ref: https://github.com/SWITCHSCIENCE/BME280)


```sh
#!/bin/bash
INFLUXDB_HOST=$1
PORT=$2
NODE=`hostname`
LOCATION="home"
STREAMS="temperature:Celcius humidity:Percent pressure:hPa"
PYTHON=/home/pi/.pyenv/shims/python
PY_SCRIPT=/home/pi/BME280/Python35/bme280.py
PY_SCRIPT_TMP=/home/pi/BME280/Python35/bme280.tmp
PY_SCRIPT_LOG=/home/pi/BME280/Python35/bme280.log
EXEC_DATE=`date +%Y-%m-%d" "%H:%M:%S`
NANO="000000000"
UNIXTIME=`date -d "${EXEC_DATE}" +%s`
DATETIME=${UNIXTIME}${NANO}

## Main
RESULT=${EXEC_DATE}
${PYTHON} ${PY_SCRIPT} > ${PY_SCRIPT_TMP}
for streams in `echo ${STREAMS}`
do
    stream=`echo ${streams} | awk -F: '{print $1}'`
    VALUE=`grep ${stream} ${PY_SCRIPT_TMP} | awk '{print $3}'`
    UNIT=`echo ${streams} | awk -F: '{print $2}'`
    curl -i -XPOST "http://${INFLUXDB_HOST}:${PORT}/write?db=sensor&u=sensor&p=password" --data-binary "${stream},node=${NODE},location=${LOCATION},unit=${UNIT} value=${VALUE} ${DATETIME}"
    RESULT+=" ${stream}:${VALUE}"
done

echo ${RESULT} >> ${PY_SCRIPT_LOG}
```

You'll get status code "204 No Content" each metrics (tempreture, humidity and pressure)


```sh
# connect to localhost port 38086 using ssh tunnel.
$ pi@sensor2:~/BME280 $ ./send_metrics.sh localhost 38086
HTTP/1.1 204 No Content
.
.
```

# 7. grafana dashboard example

Upload .json file "Sensor-1486613315807.json" from grafana ui (import dashboard).

- select a influxdb data source: sensor

You'll see "Temperature , Pressure and Humidity" on the grafana dashboard.
