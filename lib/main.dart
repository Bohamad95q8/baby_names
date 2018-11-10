import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(MyApp());

// final dummySnapshot = [
//     {"name": "Filip", "votes": 15},
//     {"name": "Abraham", "votes": 14},
//     {"name": "Richard", "votes": 11},
//     {"name": "Ike", "votes": 10},
//     {"name": "Justin", "votes": 1},
// ];

class MyApp extends StatelessWidget {
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: MyHomePage()
        );
    }
}

class MyHomePage extends StatefulWidget {
    @override
    _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    final TextEditingController _textController = new TextEditingController();
    bool _isComposing = false;
    bool _isLoading = false;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Baby Name Votes'),),
            body: Container(
                child: new Column(
                    children: <Widget>[
                        (_isLoading) ? LinearProgressIndicator() : new Text(''),
                        new Flexible(child: _buildBody(context),),
                        new Divider(height: 1.0,),
                        new Container(
                            decoration: new BoxDecoration(
                                color: Theme.of(context).cardColor
                            ),
                            child: _buildTextComposer(),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildBody(BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('baby').snapshots(),
            builder: (context, snapshot) {
                if (!snapshot.hasData) return LinearProgressIndicator();

                return _buildList(context, snapshot.data.documents);
            },
        );
    }

    Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
        return ListView(
            padding: const EdgeInsets.only(top: 20.0),
            children: snapshot.map((data) => _buildListItem(context, data)).toList(),
        );
    }

    Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
        final record = Record.fromSnapshot(data);

        return Padding(
            key: ValueKey(record.name),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListTile(
                    title: Text(record.name),
                    trailing: Text(record.votes.toString()),
                    onTap: () => Firestore.instance.runTransaction((transaction) async {
                        setState(() {
                            _isLoading = true;
                        });
                        final freshSnapshot = await transaction.get(record.reference);
                        final fresh = Record.fromSnapshot(freshSnapshot);

                        await transaction.update(record.reference, {'votes': fresh.votes + 1}).whenComplete(() {
                            setState(() {
                                _isLoading = false;                                
                            });
                        });
                    }),
                ),
            ),
        );
    }

    Widget _buildTextComposer() {
        return new IconTheme(
            data: new IconThemeData(color: Theme.of(context).accentColor),
            child: new Container(
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                child: new Row(children: <Widget>[
                    new Flexible(
                        child: new TextField(
                            controller: _textController,
                            onChanged: (String text) {
                                setState(() {
                                    _isComposing = text.length > 0;
                                });
                            },
                            onSubmitted: _handleSubmitted,
                            decoration: new InputDecoration.collapsed(
                                hintText: 'Send Message'
                            ),
                        ),
                    ),
                    new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 4.0),
                        child: new CupertinoButton(
                            child: new Text('Send'),
                            onPressed: _isComposing ? () => _handleSubmitted(_textController.text) : null,
                        )
                    )
                ],)
            ),
        );
    }

    void _handleSubmitted(String text) {
        if (text != '') {
            _textController.clear();
            setState(() {                                                    //new
                _isComposing = false;                                          //new
            }); 

            Firestore.instance.collection('baby').document()
                .setData({ 'name': text, 'votes': 0 });
        }
     }

}

class Record {
    final String name;
    final int votes;
    final DocumentReference reference;

    Record.fromMap(Map<String, dynamic> map, {this.reference})
        : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

    Record.fromSnapshot(DocumentSnapshot snapshot)
        : this.fromMap(snapshot.data, reference: snapshot.reference);

    @override
    String toString() => "Record<$name:$votes>";
}