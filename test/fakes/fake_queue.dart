// ignore_for_file: overridden_fields

import '../test.dart';

class _QueuesRepository extends QueuesRepository {
  _QueuesRepository(QueuesState state) : super(state);

  @override
  QueueSerializerType queue = FakeJsonSerializer([]);

  @override
  QueueSerializerType shuffled = FakeJsonSerializer([]);

  @override
  IdMapSerializerType idMap = FakeJsonSerializer({});
}

class FakeQueueControl extends QueueControl {
  FakeQueueControl() {
    instance = this;
  }
  static late FakeQueueControl instance;

  @override
  late final repository = _QueuesRepository(state);
}
