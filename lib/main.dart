import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gohan_map/bottom_navigation.dart';

import 'package:gohan_map/tab_navigator.dart';
import 'package:gohan_map/utils/logger.dart';
import 'package:gohan_map/utils/safearea_utils.dart';
import 'package:gohan_map/view/all_post_page.dart';
import 'package:gohan_map/view/character_page.dart';
import 'package:gohan_map/view/login_page.dart';
import 'package:gohan_map/view/map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリが起動したときに呼ばれる
void main() async {
  logger.i("start application!");
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
  ));

  // スプラッシュ画面をロードが終わるまで表示する
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(MyApp());
}
///アプリケーションの最上位のウィジェット
///ウィジェットとは、画面に表示される要素のこと。
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstLaunch;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    bool isFirst = await getIsFirstLaunch();
    setState(() {
      _isFirstLaunch = isFirst;
    });
  }

  @override
  Widget build(BuildContext context) {
    //セーフエリア外の高さを保存しておく
    SafeAreaUtil.unSafeAreaBottomHeight = MediaQuery.of(context).padding.bottom;
    SafeAreaUtil.unSafeAreaTopHeight = MediaQuery.of(context).padding.top;

    if (_isFirstLaunch == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Umap',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: (_isFirstLaunch!) ? const LoginPage() : const MainPage(),
      ),
      theme: ThemeData(
        fontFamily: (Platform.isAndroid) ? "SanFrancisco" : null,
        fontFamilyFallback: (Platform.isAndroid) ? ["HiraginoSans"] : null,
        useMaterial3: false,
      ),
    );
  }

  //最初の起動かをSharedPreferencesから取得する
  Future<bool> getIsFirstLaunch() async {
    //デバッグ用
    if (kDebugMode) {
      return true;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirstLaunch) {
      prefs.setBool('isFirstLaunch', false);
    }
    return isFirstLaunch;
  }
}

enum TabItem {
  map,
  character,
}

//タブバー(BottomNavigationBar)を含んだ全体の画面
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TabItem _currentTab = TabItem.map;
  final Map<TabItem, GlobalKey<NavigatorState>> _navigatorKeys = {
    TabItem.map: GlobalKey<NavigatorState>(),
    TabItem.character: GlobalKey<NavigatorState>(),
  };

  //globalKeyは、ウィジェットの状態を保存するためのもの
  final Map<TabItem, GlobalKey<State>> _globalKeys = {
    TabItem.map: GlobalKey<State>(),
    TabItem.character: GlobalKey<State>(),
  };

  final allpostKey = GlobalKey<AllPostPageState>();

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildTabItem(
            TabItem.map,
            '/map',
          ),
          _buildTabItem(
            TabItem.character,
            '/character',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentTab: _currentTab,
        onSelect: onSelect,
      ),
    );
  }

  Widget _buildTabItem(
    TabItem tabItem,
    String root,
  ) {
    return Offstage(
      //Offstageは、子要素を非表示にするウィジェット
      offstage: _currentTab != tabItem,
      child: TabNavigator(
        navigationKey: _navigatorKeys[tabItem]!,
        tabItem: tabItem,
        routerName: root,
        globalKey: _globalKeys[tabItem]!,
      ),
    );
  }

  //タブが選択されたときに呼ばれる。tabItemは選択されたタブ
  void onSelect(TabItem tabItem) {
    //選択されたタブをリロードする
    if (tabItem == TabItem.map) {
      MapPageState? mapPageState =
          _globalKeys[tabItem]!.currentState as MapPageState?;
      mapPageState?.reload();
    } else if (tabItem == TabItem.character) {
      CharacterPageState? characterPageState =
          _globalKeys[tabItem]!.currentState as CharacterPageState?;
      characterPageState?.reload();
    }
    //タブの最初の画面に戻る
    //_navigatorKeys[TabItem.swipe]?.currentState?.popUntil((route) => route.isFirst);
    _navigatorKeys[TabItem.map]
        ?.currentState
        ?.popUntil((route) => route.isFirst);
    _navigatorKeys[TabItem.character]
        ?.currentState
        ?.popUntil((route) => route.isFirst);
    setState(() {
      _currentTab = tabItem;
    });
  }
}
