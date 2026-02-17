#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-dummy_syslog2.log}"
LINES="${2:-200}"

# IP/계정/URI 풀
IPS=("203.0.113.10" "203.0.113.11" "198.51.100.23" "198.51.100.24" "192.0.2.55")
USERS=("admin" "root" "test" "user01" "guest")
URIS=("/login" "/admin" "/wp-login.php" "/api/auth" "/signin")

# (선택) 특정 IP를 '공격자'처럼 더 많이 나오게 만들고 싶으면 여기만 조절
ATTACKER_IP="203.0.113.10"

# 기존 파일 있으면 덮어쓰기(원하면 >> 로 append로 바꿔도 됨)
: > "$LOG_FILE"

for ((i=1; i<=LINES; i++)); do
  LEVEL=$((RANDOM % 3))
  TIME=$(date "+%b %d %H:%M:%S")

  case $LEVEL in
    0)
      MSG="INFO: System check passed"
      ;;
    1)
      MSG="WARN: Disk usage above 70%"
      ;;
    2)
      # 실패 로그인에만 IP/USER/URI 포함
      # 공격자 IP가 좀 더 자주 나오게 가중치(50%) 부여
      if (( RANDOM % 2 == 0 )); then
        ip="$ATTACKER_IP"
      else
        ip=${IPS[$RANDOM % ${#IPS[@]}]}
      fi
      user=${USERS[$RANDOM % ${#USERS[@]}]}
      uri=${URIS[$RANDOM % ${#URIS[@]}]}
      MSG="ERROR: Failed login for user=${user} from ip=${ip} uri=${uri}"
      ;;
  esac

  echo "$TIME server-app $MSG" >> "$LOG_FILE"
done

echo "더미 로그 생성 완료: $LOG_FILE (lines=$LINES)"