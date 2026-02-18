# log_practice

WSL(Ubuntu)에서 더미 syslog를 생성하고, 로그를 집계해 리포트를 만드는 Bash 자동화 실습입니다.

- v1: ERROR/WARN/INFO 집계 리포트 생성
- v2: Failed login 이벤트 기반으로 IP/URI/User TOP 집계 + 임계치 경보 + 차단 후보(IP) 목록 + IP+URI 조합 TOP 집계

## 요구 환경
- Bash, grep, awk, sed, sort, uniq, head, tail (기본 리눅스 유틸)

## 실행
### v1
1) 더미 로그 생성: `./generate_dummy_logs.sh`
2) 분석 + 리포트 생성: `./analyze_syslog.sh dummy_syslog.log`

### v2
1) 더미 로그 생성: `./generate_dummy_logs2.sh`
2) 분석 + 리포트 생성: `./analyze_syslog2.sh dummy_syslog2.log`

## 결과물
- `reports/report_YYYYmmdd_HHMMSS.txt` : 분석 리포트(로컬 보관)
- `reports/report2_YYYYmmdd_HHMMSS.txt` : 분석 리포트 v2(로컬 보관)
- `samples/sample_syslog.log` : 공개용 로그 샘플
- `samples/sample_report.txt` : 공개용 리포트 샘플
- `samples/sample_syslog2.log` : 공개용 로그 샘플(v2)
- `samples/sample_report2.txt` : 공개용 리포트 샘플(v2)

## 운영/보안
원본 로그와 reports 산출물은 용량/민감정보 가능성을 고려해 `.gitignore`로 제외하고, 재현 가능한 `samples/`만 GitHub에 공개합니다.
- ignore: `reports/`, `dummy_syslog*.log`

## 프로젝트 구조
```txt
log_practice/
├─ generate_dummy_logs.sh
├─ analyze_syslog.sh
├─ generate_dummy_logs2.sh
├─ analyze_syslog2.sh
├─ reports/
└─ samples/
   ├─ sample_syslog.log
   ├─ sample_report.txt
   ├─ sample_syslog2.log
   └─ sample_report2.txt