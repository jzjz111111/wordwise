import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库帮助类（单例模式）
/// 负责创建和管理 SQLite 数据库
class DatabaseHelper {
  // 1. 私有构造方法（单例模式）
  DatabaseHelper._privateConstructor();

  // 2. 单例实例
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // 3. 数据库实例（可能为空）
  static Database? _database;

  // 4. 获取数据库实例
  Future<Database> get database async {
    // 如果已经存在，直接返回
    if (_database != null) return _database!;
    // 否则初始化
    _database = await _initDatabase();
    return _database!;
  }

  // 5. 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取应用文档目录
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 拼接数据库文件路径
    String path = join(documentsDirectory.path, 'wordwise.db');
    // 打开数据库（如果不存在则创建）
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 6. 创建表（首次创建数据库时调用）
  Future<void> _onCreate(Database db, int version) async {
    // 创建 words 表
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        meaning TEXT NOT NULL,
        phonetic_uk TEXT,
        phonetic_us TEXT,
        example TEXT,
        category TEXT DEFAULT 'cet4'
      )
    ''');

    // 创建 study_records 表
    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,  
        review_count INTEGER DEFAULT 0,
        ease_factor REAL DEFAULT 2.5,
        interval INTEGER DEFAULT 1,
        next_review_date TEXT NOT NULL,
        last_review_date TEXT,
        mastery_level INTEGER DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      )
    ''');
   //创建wrong_words表
    await db.execute('''
      CREATE TABLE wrong_words (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       word_id INTEGER NOT NULL,
       user_id TEXT NOT NULL,  
       wrong_count INTEGER DEFAULT 1,
       last_wrong_date TEXT NOT NULL,
       FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      )
    ''');
  }

  // 7. 升级数据库（版本变化时调用）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 如果将来需要添加新表或修改表结构，在这里处理
    // 例如：await db.execute('ALTER TABLE words ADD COLUMN example TEXT');
    if(oldVersion<2){
      await db.execute('ALTER TABLE words ADD COLUMN category TEXT DEFAULT "cet4"');
    }
    if (oldVersion < 3) {
      await db.execute('''
    CREATE TABLE wrong_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id INTEGER NOT NULL,
      wrong_count INTEGER DEFAULT 1,
      last_wrong_date TEXT NOT NULL,
      FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
    )
  ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE study_records ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE wrong_words ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
    }
  }

  // 8. 插入初始数据（可选）
  Future<void> insertInitialWords(String userId) async {
    Database db = await database;

    // 检查是否已有数据
    List<Map> existing = await db.query('words');
    if (existing.isNotEmpty) return; // 已有数据则跳过

    // 插入示例单词
    List<Map<String, dynamic>> words = [
      {
        'word': 'abandon',
        'meaning': '放弃；遗弃',
        'phonetic_uk': '/əˈbændən/',
        'phonetic_us': '/əˈbændən/',
        'example': 'He abandoned his car in the snow.',
        'category':'cet4'
      },
      {
        'word': 'brilliant',
        'meaning': '聪明的；辉煌的',
        'phonetic_uk': '/ˈbrɪliənt/',
        'phonetic_us': '/ˈbrɪliənt/',
        'example': 'She has a brilliant mind.',
        'category':'cet4'
      },
      {
        'word': 'capture',
        'meaning': '捕获；占领',
        'phonetic_uk': '/ˈkæptʃə/',
        'phonetic_us': '/ˈkæptʃər/',
        'example': 'The police captured the suspect.',
        'category':'cet4'
      },
      {
        'word': 'diverse',
        'meaning': '多样的；不同的',
        'phonetic_uk': '/daɪˈvɜːs/',
        'phonetic_us': '/daɪˈvɜːrs/',
        'example': 'The city has a diverse population.',
        'category':'cet4'
      },
      {
        'word': 'evaluate',
        'meaning': '评估；评价',
        'phonetic_uk': '/ɪˈvæljueɪt/',
        'phonetic_us': '/ɪˈvæljueɪt/',
        'example': 'We need to evaluate the situation.',
        'category':'cet4'
      },
    ];

    for (var word in words) {
      // 插入单词
      int wordId = await db.insert('words', word);
      // ✅ 插入时带上 user_id
      // 同时为每个单词初始化学习记录
      await db.insert('study_records', {
        'word_id': wordId,
        'user_id': userId,
        'review_count': 0,
        'ease_factor': 2.5,
        'interval': 1,
        'next_review_date': DateTime.now().toIso8601String(),
        'last_review_date': null,
        'mastery_level': 0,
      });
    }
  }

  // 9. 关闭数据库
  Future<void> close() async {
    Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}