#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-dummy_syslog2.log}"
LINES="${2:-300}"

# ===== 튜닝 파라미터(원하면 여기만 바꿔도 됨) =====
# 시간 분산: START_TS 기준으로 i초씩 증가 + 약간의 지터(jitter)
START_TS="${START_TS:-2026-02-17 01:50:00}"  # 환경변수로 덮어쓸 수 있음
STEP_SEC="${STEP_SEC:-1}"                    # 기본 1초씩 증가
JITTER_SEC="${JITTER_SEC:-2}"                # -2~+2초 랜덤 흔들기

# 공격 버스트(급증) 구간: 버스트 동안 ERROR 비율이 확 올라가게
BURST_START="${BURST_START:-120}"            # i가 120부터 버스트 시작
BURST_LEN="${BURST_LEN:-80}"                 # 80줄 동안
BURST_ERROR_PCT="${BURST_ERROR_PCT:-80}"     # 버스트 구간에서 ERROR 확률(%)

# 평상시 레벨 비율(대략): INFO/WARN/ERROR
NORMAL_INFO_PCT="${NORMAL_INFO_PCT:-60}"
NORMAL_WARN_PCT="${NORMAL_WARN_PCT:-25}"
NORMAL_ERROR_PCT="${NORMAL_ERROR_PCT:-15}"

# 공격자 가중치
ATTACKER_IP="${ATTACKER_IP:-203.0.113.10}"
ATTACKER_WEIGHT_PCT="${ATTACKER_WEIGHT_PCT:-55}" # ERROR일 때 공격자 IP가 나올 확률(%)

# 디스크 사용률(점진 상승 느낌)
DISK_BASE="${DISK_BASE:-68}"   # 시작 %
DISK_MAX="${DISK_MAX:-92}"     # 최대 %
DISK_STEP_EVERY="${DISK_STEP_EVERY:-40}" # 40줄마다 1~2%씩 올라가는 느낌

# 시드 고정(재현성 원하면 SEED=123 같은 식으로 실행)
if [[ -n "${SEED:-}" ]]; then
  RANDOM="$SEED"
fi

# ===== 풀 =====
IPS=("203.0.113.10" "203.0.113.11" "198.51.100.23" "198.51.100.24" "192.0.2.55")
USERS=("admin" "root" "test" "user01" "guest")
URIS=("/login" "/admin" "/wp-login.php" "/api/auth" "/signin")

# ===== 파일 초기화 =====
: > "$LOG_FILE"

# START_TS를 epoch로 변환(리눅스 date 기준)
start_epoch=$(date -d "$START_TS" +%s)

disk="$DISK_BASE"

pick_level_normal() {
  # 0=INFO, 1=WARN, 2=ERROR
  r=$((RANDOM % 100))
  if (( r < NORMAL_INFO_PCT )); then
    echo 0
  elif (( r < NORMAL_INFO_PCT + NORMAL_WARN_PCT )); then
    echo 1
  else
    echo 2
  fi
}

pick_level_burst() {
  # 버스트에서는 ERROR 비율만 강제로 높임(나머지는 INFO/WARN로 분배)
  r=$((RANDOM % 100))
  if (( r < BURST_ERROR_PCT )); then
    echo 2
  else
    # 남은 구간은 INFO/WARN 7:3 정도로
    rr=$((RANDOM % 10))
    if (( rr < 7 )); then echo 0; else echo 1; fi
  fi
}

calc_time() {
  # 기본 i초 증가 + 지터(-JITTER~+JITTER)
  local i="$1"
  local jitter=0
  if (( JITTER_SEC > 0 )); then
    jitter=$(( (RANDOM % (JITTER_SEC*2 + 1)) - JITTER_SEC ))
  fi
  local epoch=$(( start_epoch + (i-1)*STEP_SEC + jitter ))
  date -d "@$epoch" "+%b %d %H:%M:%S"
}

pick_attacker_ip() {
  r=$((RANDOM % 100))
  if (( r < ATTACKER_WEIGHT_PCT )); then
    echo "$ATTACKER_IP"
  else
    echo "${IPS[$RANDOM % ${#IPS[@]}]}"
  fi
}

# ===== 생성 루프 =====
for ((i=1; i<=LINES; i++)); do
  TIME="$(calc_time "$i")"

  # 디스크 점진 상승(가끔씩만)
  if (( i % DISK_STEP_EVERY == 0 )); then
    inc=$(( (RANDOM % 2) + 1 )) # 1~2
    disk=$((disk + inc))
    if (( disk > DISK_MAX )); then disk="$DISK_MAX"; fi
  fi

  # 버스트 구간 여부
  if (( i >= BURST_START && i < BURST_START + BURST_LEN )); then
    LEVEL="$(pick_level_burst)"
  else
    LEVEL="$(pick_level_normal)"
  fi

  case "$LEVEL" in
    0)
      MSG="INFO: System check passed"
      ;;
    1)
      # 70% 넘으면 WARN을 찍되, 수치도 포함(운영 로그 느낌)
      if (( disk >= 70 )); then
        MSG="WARN: Disk usage above 70% (usage=${disk}%)"
      else
        # 70 미만이면 가끔 INFO로 흐름도 섞어줌
        MSG="INFO: Disk usage normal (usage=${disk}%)"
      fi
      ;;
    2)
      # 실패 로그인: IP/USER/URI 포함
      ip="$(pick_attacker_ip)"
      user="${USERS[$RANDOM % ${#USERS[@]}]}"
      uri="${URIS[$RANDOM % ${#URIS[@]}]}"

      # (옵션) wp-login.php 같은 URI면 root/admin 타겟이 조금 더 많게(현실감)
      if [[ "$uri" == "/wp-login.php" || "$uri" == "/admin" ]]; then
        t=$((RANDOM % 100))
        if (( t < 40 )); then
          user=$([[ $((RANDOM % 2)) -eq 0 ]] && echo "root" || echo "admin")
        fi
      fi

      MSG="ERROR: Failed login for user=${user} from ip=${ip} uri=${uri}"
      ;;
  esac

  echo "$TIME server-app $MSG" >> "$LOG_FILE"
done

echo "더미 로그 생성 완료: $LOG_FILE (lines=$LINES, start='$START_TS')"
echo "옵션 예시: SEED=123 BURST_START=50 BURST_LEN=120 BURST_ERROR_PCT=90 ./generate_dummy_logs2.sh dummy_syslog2.log 400"