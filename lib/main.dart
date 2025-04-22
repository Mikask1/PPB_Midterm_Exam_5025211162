import 'package:flutter/material.dart';
import 'package:my_first_app/empty_book.dart';
import 'book.dart';
import 'user.dart';
import 'book_card.dart';
import 'book_dialog.dart';
import 'user_list.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

void main() => runApp(MaterialApp(home: BookList()));

class BookList extends StatefulWidget {
  const BookList({super.key});

  @override
  _BookListState createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  static final _uuid = Uuid();
  late List<Book> books = [];
  late List<User> users = [];
  final dbHelper = DatabaseHelper.instance;
  bool isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetAndLoadData();
  }

  Future<void> _resetAndLoadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error resetting database: ${e.toString()}');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    await _loadUsersFromDB();
    await _loadBooksFromDB();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUsersFromDB() async {
    try {
      final allUsers = await dbHelper.getAllUsers();
      if (mounted) {
        setState(() {
          users = allUsers;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load users');
    }
  }

  Future<void> _loadBooksFromDB() async {
    try {
      final allBooks = await dbHelper.getAllBooks();

      if (mounted) {
        setState(() {
          books = allBooks;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load books');
    }
  }

  Future<void> _addUser(
    String name,
    int age,
    String gender,
    String hometown,
    String? profilePicture,
  ) async {
    try {
      final user = User(
        id: _uuid.v4(),
        name: name,
        age: age,
        gender: gender,
        hometown: hometown,
        profilePicture: profilePicture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbHelper.insertUser(user);
      await _loadUsersFromDB();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await dbHelper.deleteUser(userId);
      await _loadUsersFromDB();
    } catch (e) {
      _showErrorSnackBar('Failed to delete user');
    }
  }

  Future<void> _updateUser(
    User user,
    String name,
    int age,
    String gender,
    String hometown,
    String? profilePicture,
  ) async {
    try {
      final updatedUser = User(
        name: name,
        age: age,
        id: user.id,
        profilePicture: profilePicture,
        gender: gender,
        hometown: hometown,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      await dbHelper.updateUser(updatedUser);
      await _loadUsersFromDB();
    } catch (e) {
      _showErrorSnackBar('Failed to update book');
    }
  }

  Future<void> _addBook(
    String title,
    String text,
    String userId,
    String? imagePath,
  ) async {
    try {
      final book = Book(
        title: title,
        text: text,
        id: _uuid.v4(),
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imagePath: imagePath,
      );

      await dbHelper.insertBook(book);
      await _loadBooksFromDB();
    } catch (e) {
      _showErrorSnackBar('Failed to add book');
    }
  }

  Future<void> _updateBook(
    Book book,
    String title,
    String newText,
    String userId,
    String? newImagePath,
  ) async {
    try {
      final updatedBook = Book(
        title: title,
        text: newText,
        id: book.id,
        userId: userId,
        createdAt: book.createdAt,
        updatedAt: DateTime.now(),
        imagePath: newImagePath,
      );

      await dbHelper.updateBook(updatedBook);
      await _loadBooksFromDB();
    } catch (e) {
      _showErrorSnackBar('Failed to update book');
    }
  }

  Future<void> _deleteBook(Book book) async {
    try {
      await dbHelper.deleteBook(book.id);
      await _loadBooksFromDB();
    } catch (e) {
      _showErrorSnackBar('Failed to delete book');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.grey[200],
        ),
        Image.asset(
          "assets/image.jpg",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.2),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.yellow.shade500,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return BookDialog(
                    users: users,
                    onSubmit: (title, text, userId, imagePath) {
                      _addBook(title, text, userId, imagePath);
                    },
                  );
                },
              );
            },
            child: Icon(Icons.add, color: Colors.blue.shade500),
          ),
          appBar: AppBar(
            title: Text(
              'StoryBase',
              style: TextStyle(
                color: Colors.blue.shade500,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            centerTitle: false,
            backgroundColor: Colors.yellow.shade500,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                color: Colors.blue.shade500,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            actions: <Widget>[
              if (_currentTabIndex == 0)
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (users.isEmpty) {
                      _showErrorSnackBar(
                        'Please add a user first before creating a book',
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return BookDialog(
                          users: users,
                          onSubmit: (title, text, userId, imagePath) {
                            _addBook(title, text, userId, imagePath);
                          },
                        );
                      },
                    );
                  },
                  tooltip: 'Create Book',
                ),
            ],
          ),
          body:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Books'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            ],
            enableFeedback: false,
            selectedItemColor: Colors.yellow.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_currentTabIndex == 0) {
      return _buildBooksList();
    } else if (_currentTabIndex == 1) {
      return _buildUsersList();
    } else {
      return Container();
    }
  }

  Widget _buildBooksList() {
    return books.isEmpty
        ? EmptyBook(hasUsers: users.isNotEmpty)
        : ListView.builder(
          itemCount: books.length,
          shrinkWrap: true,
          physics: ScrollPhysics(),
          itemBuilder: (context, index) {
            return BookCard(
              book: books[index],
              update: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return BookDialog(
                      book: books[index],
                      users: users,
                      onSubmit: (newTitle, newText, userId, newImagePath) {
                        _updateBook(
                          books[index],
                          newTitle,
                          newText,
                          userId,
                          newImagePath,
                        );
                      },
                    );
                  },
                );
              },
              delete: () {
                _deleteBook(books[index]);
              },
            );
          },
        );
  }

  Widget _buildUsersList() {
    return SingleChildScrollView(
      child: UserList(
        users: users,
        addUser: _addUser,
        onDelete: (index) => _deleteUser(users[index].id),
        onUpdate:
            (user, name, age, gender, hometown, profilePicture) =>
                _updateUser(user, name, age, gender, hometown, profilePicture),
      ),
    );
  }
}
