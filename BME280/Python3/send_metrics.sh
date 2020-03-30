#!/bin/bash
INFLUXDB_HOST=$1
PORT=$2
NODE=`hostname`
LOCATION="home"
STREAMS="temperature:Celcius humidity:Percent pressure:hPa"
PYTHON=/home/pi/venv/bin/python
PY_SCRIPT=/home/pi/BME280/Python3/bme280.py
PY_SCRIPT_TMP=/home/pi/BME280/Python3/bme280.tmp
PY_SCRIPT_LOG=/home/pi/BME280/Python3/bme280.log
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