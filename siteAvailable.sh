#!/bin/bash

# Constants
FROM_MAIL="no-reply@mkutin.ru"
SERVER_NAME=$HOSTNAME
SITE_LIST="site.txt"
EMAIL_LIST="email.txt"
SUBJECT_MAIL="Отчет о проверке доступности сайтов"

# Lists for responce 
bad_list=""
ok_list=""

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

    status=`curl --write-out %{http_code} --silent --output /dev/null ${aliasArray[$a]}`

    # Check status code
    if [ "$status" != "200" ] && [ "$status" != "301" ]; then
		bad_list="$bad_list<li><p class='info'>Недоступен сайт <b>${aliasArray[$a]}</b>.<br />Статус возвращаемого ответа - <span class='bad_code'>$status</span><br />Проверка в $CHECK_TIME</p></li>"
	else
		ok_list="$ok_list<li><p class='info'> С адресом <b>${aliasArray[$a]}</b> все в порядке.<br />Статус возвращаемого ответа - <span class='ok_code'>$status</span><br />Проверка в $CHECK_TIME</p></li>"
	fi
done

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
			<hr /><br />
			<p align='left'>Следующие сайты <span class='ok_code'>ответили положительным статусом</span>:</p>
			<hr />
				<ol>$ok_list</ol>
			<hr />
			<p align='right'>Отправлено с $SERVER_NAME</p>
		</body>
	</html>
"

# Send email to someone
for ((a=0; a < ${#emailArray[*]}; a++)); do
    MAIL_TXT="Subject: $SUBJECT_MAIL\nFrom: $FROM_MAIL\nTo: ${emailArray[$a]}\nContent-Type: text/html; charset=utf-8\nMIME-Version: 1.0\n\n$HTML"

    echo -e $MAIL_TXT | /usr/sbin/sendmail -t
done
