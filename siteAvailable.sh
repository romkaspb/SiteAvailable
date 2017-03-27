#!/bin/bash

# Constants
START=$(date +%s)
FROM_MAIL="no-reply@example.ru"
SERVER_NAME=$HOSTNAME
SITE_LIST="sites.txt"
EMAIL_LIST="emails.txt"
OK_LIST="_ok.txt"
BAD_LIST="_bad.txt"
SUBJECT_MAIL="Отчет о проверке доступности сайтов"

# Get alias from site.txt
index=0
while read line; do 
	aliasArray[$index]="$line"
	index=$(($index+1))
done < $SITE_LIST

# Get email from email.txt
index=0
while read line; do 
	emailArray[$index]="$line"
	index=$(($index+1))
done < $EMAIL_LIST

# Get http response with status
for ((a=0; a < ${#aliasArray[*]}; a++)); do
    CHECK_TIME=$(date +"%d-%m-%Y %H:%M:%S")

    status=$(curl --write-out %{http_code} --silent --output /dev/null ${aliasArray[$a]}) && {
    	# echo "$a. ${aliasArray[$a]} - $status"

    	# Check status code
	    if [ "$status" != "200" ] && [ "$status" != "301" ] && [ "$status" != "000" ]; then
			echo "$bad_list<li><p class='info'>Недоступен сайт <b>${aliasArray[$a]}</b>.<br />Статус возвращаемого ответа - <span class='bad_code'>$status</span><br />Проверка в $CHECK_TIME</p></li>" >> $BAD_LIST

			FLAG=$(($FLAG+1))
		else
			echo "$ok_list<li><p class='info'>Доступен сайт <b>${aliasArray[$a]}</b>.<br />Статус возвращаемого ответа - <span class='ok_code'>$status</span><br />Проверка в $CHECK_TIME</p></li>" >> $OK_LIST
		fi
    } &
done

wait

# Lists for responce 
bad_list=`cat $BAD_LIST`
ok_list=`cat $OK_LIST`

# Render mail 
HTML="
	<html>
		<head>
			<title>$SUBJECT_MAIL</title>
			<style>
				body {
					font-family: monospace;
				}

				a {
					text-decoration: none;
					color: black;
				}

				.bad_code {
					color: red;
				}

				.ok_code {
					color: green;
				}

				.info {
					line-height: 20px;
					text-align: center;
				}
			</style>
		</head>

		<body>
			<h2 align='center'>Автоматический отчет сервера о проверке доступности сайтов</h2><br />
			<p align='left'>Следующие сайты <span class='bad_code'>не ответили положительным статусом</span>:</p>
			<hr />
				<ol>$bad_list</ol>
			<hr />
			<hr />
				<ol>$ok_list</ol>
			<hr />
			<p align='right'>Отправлено с $SERVER_NAME</p>
		</body>
	</html>
"
if [ -n "$bad_list" ]; then
	# Send email to someone from email.txt
	for ((a=0; a < ${#emailArray[*]}; a++)); do
	    MAIL_TXT="Subject: $SUBJECT_MAIL\nFrom: $FROM_MAIL\nTo: ${emailArray[$a]}\nContent-Type: text/html; charset=utf-8\nMIME-Version: 1.0\n\n$HTML"

	    echo -e $MAIL_TXT | /usr/sbin/sendmail -t
	done
fi

`rm $BAD_LIST` && `rm $OK_LIST`

END=$(date +%s)

DIFF=$(( $END - $START ))

# echo "It took $DIFF seconds. START - $START, END - $END"

# Send mail to programmer
# MAIL_TXT="Subject: $SUBJECT_MAIL\nFrom: $FROM_MAIL\nTo: mk@ifrog.ru\nContent-Type: text/html; charset=utf-8\nMIME-Version: 1.0\n\n$HTML"

# echo -e $MAIL_TXT | /usr/sbin/sendmail -t