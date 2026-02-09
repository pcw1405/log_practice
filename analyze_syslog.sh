#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-dummy_syslog.log}"
OUT_DIR="reports"
SAMPLE_DIR="samples"
mkdir -p "$OUT_DIR" "$SAMPLE_DIR"

# 입력 파일 체크(없으면 친절하게 종료)
if [ ! -f "$LOG_FILE" ]; then
  echo "[ERROR] 로그 파일이 없습니다: $LOG_FILE"
  echo "사용법: ./analyze_syslog.sh [logfile]"
  exit 1
fi

TS="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="${OUT_DIR}/report_${TS}.txt"

# 기본 통계
total=$(wc -l < "$LOG_FILE")
error=$(grep -c " ERROR:" "$LOG_FILE" || true)
warn=$(grep -c " WARN:" "$LOG_FILE" || true)
info=$(grep -c " INFO:" "$LOG_FILE" || true)

# 보안/운영 포인트(지금 더미로그에 맞춘 실패 로그인 경보)
fail_cnt=$(grep -c "Failed login" "$LOG_FILE" || true)
ALERT_THRESHOLD=5

{
  echo "==== 로그 분석 리포트 ===="
  echo "대상 파일: ${LOG_FILE}"
  echo "생성 시각: $(date +'%F %T')"
  echo "전체 로그 수: ${total}"
  echo "ERROR 수: ${error}"
  echo "WARN 수: ${warn}"
  echo "INFO 수: ${info}"

  echo ""
  echo "ERROR 메시지 TOP5:"
  # ERROR: 뒤의 메시지만 뽑아 빈도 TOP5 집계 (에러 0건이어도 멈추지 않게 처리)
  grep -E "ERROR:" "$LOG_FILE" \
    | sed 's/.*ERROR: *//' \
    | sort | uniq -c | sort -nr | head -n 5 || true

  echo ""
  echo "로그인 실패 총합: ${fail_cnt}"
  if [ "$fail_cnt" -ge "$ALERT_THRESHOLD" ]; then
    echo "[ALERT] 브루트포스 의심: 실패 로그인 ${ALERT_THRESHOLD}회 이상"
  else
    echo "[OK] 로그인 실패가 임계치(${ALERT_THRESHOLD}) 미만"
  fi

  echo ""
  echo "최근 10줄:"
  tail -n 10 "$LOG_FILE"
} > "$OUT_FILE"

# 샘플 파일 갱신(학습/깃허브 업로드용)
head -n 20 "$LOG_FILE" > "${SAMPLE_DIR}/sample_syslog.log"
head -n 40 "$OUT_FILE" > "${SAMPLE_DIR}/sample_report.txt"
echo "샘플 갱신: ${SAMPLE_DIR}/sample_syslog.log, ${SAMPLE_DIR}/sample_report.txt"

echo "완료: $OUT_FILE"