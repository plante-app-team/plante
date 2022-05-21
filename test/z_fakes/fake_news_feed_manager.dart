import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';

class FakeNewsFeedManager implements NewsFeedManager {
  final _news = <NewsPiece>[];
  final _errorsForPages = <int, GeneralError>{};
  final _obtainedPages = <int>[];
  final int pageSizeTesting;

  FakeNewsFeedManager({this.pageSizeTesting = 10});

  // ignore: non_constant_identifier_names
  void setErrorForPage_testing(int page, GeneralError? error) {
    if (error != null) {
      _errorsForPages[page] = error;
    } else {
      _errorsForPages.remove(page);
    }
  }

  // ignore: non_constant_identifier_names
  void addNewsPiece_testing(NewsPiece newsPiece) {
    _news.add(newsPiece);
  }

  // ignore: non_constant_identifier_names
  void deleteAllNews_testing() {
    _news.clear();
  }

  // ignore: non_constant_identifier_names
  List<int> obtainedPages_testing() => List.unmodifiable(_obtainedPages);

  @override
  Future<Result<List<NewsPiece>, GeneralError>> obtainNews(
      {required int page, required Coord center}) async {
    _obtainedPages.add(page);

    final error = _errorsForPages[page];
    if (error != null) {
      return Err(error);
    }

    final pageStart = page * pageSizeTesting;
    if (_news.length <= pageStart) {
      return Ok(const []);
    }
    var pageEnd = pageStart + pageSizeTesting;
    if (_news.length < pageEnd) {
      pageEnd = _news.length;
    }
    return Ok(_news.sublist(pageStart, pageEnd));
  }
}
