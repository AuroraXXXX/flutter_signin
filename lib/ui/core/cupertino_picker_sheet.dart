import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showCupertinoTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  // CupertinoDatePicker 使用 DateTime，因此把 TimeOfDay 暂时挂到今天的日期上。
  final now = DateTime.now();
  final initial = DateTime(
    now.year,
    now.month,
    now.day,
    initialTime.hour,
    initialTime.minute,
  );
  final selected = await _showPickerSheet(
    context: context,
    initial: initial,
    mode: CupertinoDatePickerMode.time,
  );
  return selected == null ? null : TimeOfDay.fromDateTime(selected);
}

Future<DateTime?> showCupertinoDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) => _showPickerSheet(
  context: context,
  initial: initialDate,
  mode: CupertinoDatePickerMode.date,
  minimumDate: minimumDate,
  maximumDate: maximumDate,
);

Future<DateTime?> showCupertinoMonthPicker({
  required BuildContext context,
  required DateTime initialMonth,
  required DateTime minimumMonth,
  required DateTime maximumMonth,
}) => _showPickerSheet(
  context: context,
  initial: initialMonth,
  mode: CupertinoDatePickerMode.monthYear,
  minimumDate: minimumMonth,
  maximumDate: maximumMonth,
);

Future<DateTime?> _showPickerSheet({
  required BuildContext context,
  required DateTime initial,
  required CupertinoDatePickerMode mode,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) {
  // 统一封装底部弹层、取消/确定按钮和鼠标滚轮支持。
  var selected = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: false,
    enableDrag: false,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, selected),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ScrollConfiguration(
                behavior: const _PickerScrollBehavior(),
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: initial,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  use24hFormat: true,
                  minuteInterval: 1,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerScrollBehavior extends CupertinoScrollBehavior {
  const _PickerScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
