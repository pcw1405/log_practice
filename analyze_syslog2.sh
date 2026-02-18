#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-dummy_syslog2.log}"
OUT_DIR="reports"
SAMPLE_DIR="samples"
mkdir -p "$OUT_DIR" "$SAMPLE_DIR"

# 입력 파일 체크
if [ ! -f "$LOG_FILE" ]; then
  echo "[ERROR] 로그 파일이 없습니다: $LOG_FILE"
  echo "사용법: ./analyze_syslog2.sh [logfile]"
  exit 1
fi

TS="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="${OUT_DIR}/report2_${TS}.txt"

# 기본 통계
total=$(wc -l < "$LOG_FILE")
error=$(grep -c " ERROR:" "$LOG_FILE" || true)
warn=$(grep -c " WARN:" "$LOG_FILE" || true)
info=$(grep -c " INFO:" "$LOG_FILE" || true)

ALERT_THRESHOLD=5

# (핵심) Failed login 라인만 1번 뽑아서 재사용
fail_lines="$(grep "Failed login" "$LOG_FILE" || true)"
if [ -n "$fail_lines" ]; then
  fail_cnt=$(printf "%s\n" "$fail_lines" | wc -l | tr -d ' ')
else
  fail_cnt=0
fi

# 추출 함수(포맷이 바뀌어도 여기만 고치면 됨)
extract_ip()   { sed -n 's/.* ip=\([0-9.]\+\).*/\1/p'; }
extract_user() { sed -n 's/.* user=\([^ ]\+\) .*/\1/p'; }
extract_uri()  { sed -n 's/.* uri=\([^ ]\+\).*/\1/p'; }

{
  echo "==== 로그 분석 리포트 v2 ===="
  echo "대상 파일: ${LOG_FILE}"
  echo "생성 시각: $(date +'%F %T')"
  echo ""

  echo "[기본 통계]"
  echo "전체 로그 수: ${total}"
  echo "ERROR 수: ${error}"
  echo "WARN 수: ${warn}"
  echo "INFO 수: ${info}"
  echo ""

  echo "[보안 이벤트]"
  echo "Failed login 수: ${fail_cnt}"
  if [ "$fail_cnt" -ge "$ALERT_THRESHOLD" ]; then
    echo "ALERT: Failed login이 임계치(${ALERT_THRESHOLD}) 이상입니다."
  else
    echo "OK: Failed login이 임계치(${ALERT_THRESHOLD}) 미만입니다."
  fi

  echo ""
  echo "[Failed login IP TOP5]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" | extract_ip | sort | uniq -c | sort -nr | head -n 5 || true
  else
    echo "(데이터 없음)"
  fi

  echo ""
  echo "[차단 후보(IP) - ${ALERT_THRESHOLD}회 이상]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" | extract_ip | sort | uniq -c \
      | awk -v th="$ALERT_THRESHOLD" '$1>=th {print}' | sort -nr || true
  else
    echo "(데이터 없음)"
  fi

  echo ""
  echo "[공격 타겟 URI TOP5]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" | extract_uri | sort | uniq -c | sort -nr | head -n 5 || true
  else
    echo "(데이터 없음)"
  fi

  # ✅ 이번에 추가되는 섹션: IP + URI 조합 TOP5
  echo ""
  echo "[IP + URI 조합 TOP5]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" \
      | awk -F'ip=| uri=' '{print $2, $3}' \
      | sort | uniq -c | sort -nr | head -n 5 || true
  else
    echo "(데이터 없음)"
  fi

  echo ""
  echo "[타겟 계정 USER TOP5]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" | extract_user | sort | uniq -c | sort -nr | head -n 5 || true
  else
    echo "(데이터 없음)"
  fi

  echo ""
  echo "[최근 Failed login 10줄]"
  if [ "$fail_cnt" -gt 0 ]; then
    printf "%s\n" "$fail_lines" | tail -n 10 || true
  else
    echo "(데이터 없음)"
  fi
} > "$OUT_FILE"

echo "리포트 생성 완료: $OUT_FILE"