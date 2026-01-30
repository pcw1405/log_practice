# log_practice

WSL(Ubuntu)에서 더미 syslog를 생성하고, ERROR/WARN/INFO를 집계해 리포트를 만드는 자동화 실습입니다.

## 실행
1) 더미 로그 생성: ./generate_dummy_logs.sh
2) 분석 + 리포트 생성: ./analyze_syslog.sh dummy_syslog.log

## 결과물
- reports/report_YYYYmmdd_HHMMSS.txt : 분석 리포트(로컬 보관)
- samples/sample_syslog.log : 공개용 로그 샘플(앞 20줄)
- samples/sample_report.txt : 공개용 리포트 샘플(앞 15줄)

## 운영/보안
원본 로그와 reports 산출물은 .gitignore로 제외하고, samples만 GitHub에 공개합니다.
