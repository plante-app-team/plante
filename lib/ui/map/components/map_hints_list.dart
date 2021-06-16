import 'package:flutter/material.dart';
import 'package:plante/ui/map/components/map_hint_widget.dart';

class MapHintsListController {
  final _items = <_MapHintItem>[];
  final _observers = <_MapHintsListControllerObserver>[];

  void addHint(String id, String text) {
    removeHint(id);
    _items.add(_MapHintItem(id, text));
    _observers.forEach((e) {
      e.onItemAdded(_items.length - 1, _items.last);
    });
  }

  void removeHint(String id) {
    final existingIndex = _items.indexWhere((element) => element.id == id);
    if (existingIndex != -1) {
      final removed = _items.removeAt(existingIndex);
      _observers.forEach((e) {
        e.onItemRemoved(existingIndex, removed);
      });
    }
  }

  void _addObserver(_MapHintsListControllerObserver observer) {
    _observers.add(observer);
  }

  void _removeObserver(_MapHintsListControllerObserver observer) {
    _observers.remove(observer);
  }
}

class MapHintsList extends StatefulWidget {
  final MapHintsListController controller;
  const MapHintsList({Key? key, required this.controller}) : super(key: key);

  @override
  _MapHintsListState createState() => _MapHintsListState();
}

class _MapHintsListState extends State<MapHintsList>
    implements _MapHintsListControllerObserver {
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    widget.controller._addObserver(this);
  }

  @override
  void dispose() {
    widget.controller._removeObserver(this);
    super.dispose();
  }

  @override
  void onItemAdded(int index, _MapHintItem item) {
    _listKey.currentState!.insertItem(index);
  }

  @override
  void onItemRemoved(int index, _MapHintItem item) {
    _listKey.currentState!.removeItem(index, (context, animation) {
      return FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MapHintWidget(item.text)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      initialItemCount: widget.controller._items.length,
      itemBuilder:
          (BuildContext context, int index, Animation<double> animation) {
        final item = widget.controller._items[index];
        final result = MapHintWidget(item.text, onCanceledCallback: () {
          widget.controller.removeHint(item.id);
        });
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 4), child: result),
          ),
        );
      },
    );
  }
}

class _MapHintItem {
  final String id;
  final String text;
  _MapHintItem(this.id, this.text);
}

abstract class _MapHintsListControllerObserver {
  void onItemAdded(int index, _MapHintItem item);
  void onItemRemoved(int index, _MapHintItem item);
}
