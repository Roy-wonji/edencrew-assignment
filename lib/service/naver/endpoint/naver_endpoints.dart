abstract final class NaverEndpoints {
  static const headers = {
    'Accept': '*/*',
    'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
    'Referer': 'https://finance.naver.com/',
    'User-Agent': 'Mozilla/5.0 EdencrewAssignment/1.0',
  };
  static Uri search(String query) => Uri.https('ac.stock.naver.com', '/ac', {
    'q': query,
    'target': 'stock,ipo,index,marketindicator',
  });
  static Uri metadata(String symbol) => Uri.https(
    'stock.naver.com',
    '/api/securityFe/api/fchart/domestic/stock/$symbol',
  );
  static Uri quotes(List<String> symbols) => Uri.https(
    'polling.finance.naver.com',
    '/api/realtime',
    {'query': 'SERVICE_ITEM:${symbols.join(',')}'},
  );
  static Uri history(String symbol, int page) => Uri.https(
    'finance.naver.com',
    '/item/sise_day.naver',
    {'code': symbol, 'page': '$page'},
  );
}
