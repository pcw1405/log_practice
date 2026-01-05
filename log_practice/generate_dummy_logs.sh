LOG_FILE="dummy_syslog.log"

for i in {1..200}
do
  LEVEL=$((RANDOM % 3))
  TIME=$(date "+%b %d %H:%M:%S")

  case $LEVEL in
    0) MSG="INFO: System check passed" ;;
    1) MSG="WARN: Disk usage above 70%" ;;
    2) MSG="ERROR: Failed login attempt" ;;
  esac

  echo "$TIME server-app $MSG" >> $LOG_FILE
done

echo "더미 로그 생성 완료: $LOG_FILE"
