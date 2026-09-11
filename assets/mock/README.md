이 폴더에 목업/샘플 데이터(JSON 등)를 넣어 주세요.

## Naver sample responses

- `naver_search_samsung.json`
  - `https://ac.stock.naver.com/ac?q=삼성&target=stock,ipo,index,marketindicator`
- `naver_realtime_005930_000660.json`
  - `https://polling.finance.naver.com/api/realtime?query=SERVICE_ITEM:005930,000660`
- `naver_metadata_005930.json`
  - `https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/005930`
- `naver_sise_day_005930_page1.html`
  - `https://finance.naver.com/item/sise_day.naver?code=005930&page=1`

Fetched on 2026-09-10 for parser development. The daily price endpoint is HTML,
so parser tests use byte-level ASCII structure and do not assume UTF-8 Korean
text decoding.
