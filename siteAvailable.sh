#!/bin/bash

TO_MAIL="maks.kutin@gmail.com"
FROM_MAIL="no-reply@mkutin.ru"
SERVER_NAME=$HOSTNAME

index=0

# Write alias of site into array from site.txt
while read line; do 
	aliasArray[$index]="$line"
	index=$(($index+1))
done < site.txt

# Get http response with status
for ((a=0; a < ${#aliasArray[*]}; a++)); do
    status=`curl --write-out %{http_code} --silent --output /dev/null ${aliasArray[$a]}`

    # Check status code
    if [ "$status" != "200" ] && [ "$status" != "301" ]; then
		SUBJECT_MAIL="Проблемы с доступом к сайту"
		HTML="Оповещение о проблеме доступа к сайту"
		CHECK_TIME=$(date +"%d-%m-%Y %H:%M:%S")

		SUBJECT_MAIL="$SUBJECT_MAIL ${aliasArray[$a]}"
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

						.important {
							color: red;
						}

						.info {
							line-height: 20px;
							text-align: center;
						}
					</style>
				</head>

				<body>
					<h2 align='center'>Проблемы с доступностью сайта</h2>
					<hr />
					<p class='info'>$HTML <b>${aliasArray[$a]}</b>.<br />Статус возвращаемого ответа - <span class='important'>$status</span><br />Проверка в $CHECK_TIME</p>
					<hr />
					<p align='right'>Отправлено с $SERVER_NAME</p>
				</body>
			</html>
		"

		MAIL_TXT="Subject: $SUBJECT_MAIL\nFrom: $FROM_MAIL\nTo: $TO_MAIL\nContent-Type: text/html\nMIME-Version: 1.0\n\n$HTML"

		echo -e $MAIL_TXT | /usr/sbin/sendmail -t
	fi
done