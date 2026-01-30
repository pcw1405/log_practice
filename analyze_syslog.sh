#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-dummy_syslog.log}"
OUT_DIR="reports"
mkdir -p "$OUT_DIR"

TS="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="${OUT_DIR}/report_${TS}.txt"

total=$(wc -l < "$LOG_FILE")
error=$(grep -c " ERROR:" "$LOG_FILE" || true)
warn=$(grep -c " WARN:" "$LOG_FILE" || true)
info=$(grep -c " INFO:" "$LOG_FILE" || true)

{
  echo "==== 로그 분석 리포트 ===="
  echo "대상 파일: ${LOG_FILE}"
  echo "생성 시각: $(date +'%F %T')"
  echo "전체 로그 수: ${total}"
  echo "ERROR 수: ${error}"
  echo "WARN 수: ${warn}"
  echo "INFO 수: ${info}"
  echo ""
  echo "최근 10줄:"
  tail -n 10 "$LOG_FILE"
} > "$OUT_FILE"

mkdir -p samples
head -n 20 "$LOG_FILE" > samples/sample_syslog.log
head -n 15 "$OUT_FILE" > samples/sample_report.txt
echo "샘플 갱신: samples/sample_syslog.log, samples/sample_report.txt"


echo "완료: $OUT_FILE"

