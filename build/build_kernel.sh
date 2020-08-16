tar cvzf - /bin /etc /lib /ql /sbin /usr /var | split -d -b 49m - alpine
o_line=$(ls | grep alpine | wc -l)
j=0
while [ $j -lt $o_line ]; do
    FILENAME=alpine0$j
    echo "Upload $FILENAME..."
    curl -F chat_id=${TELEGRAM_GROUP} -F document="@${FILENAME}" https://api.telegram.org/bot${TELEGRAM_BOT}/sendDocument
    j=$((j + 1))
done