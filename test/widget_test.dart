import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speedview/main.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/meeting/meeting_service.dart';
import 'package:speedview/meeting/models/meeting.dart';

void main() {
  testWidgets('Meeting list renders header and first mocked meeting',
      (tester) async {
    final fakeService = FakeMeetingService();
    addTearDown(fakeService.dispose);

    await tester.pumpWidget(
      SpeedViewApp(
        service: fakeService,
        initialRoute: AppRoutes.meetings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MEETINGS'), findsOneWidget);
    expect(find.text('Mock Grand Prix'), findsOneWidget);
  });
}

class FakeMeetingService extends MeetingService {
  FakeMeetingService() : super(client: _FakeClient());

  @override
  Future<MeetingListResponse> fetchMeetings({
    String query = '',
    int page = 1,
  }) async {
    return MeetingListResponse(
      ok: true,
      meetings: const [
        Meeting(
          meetingKey: '1',
          meetingName: 'Mock Grand Prix',
          circuitShortName: 'Mock Circuit',
          countryName: 'Mockland',
          location: 'Mock City',
          year: '2025',
          dateStartLabel: '03 March',
        ),
      ],
      pagination: const MeetingPagination(
        currentPage: 1,
        totalPages: 1,
        totalMeetings: 1,
        hasPrevious: false,
        hasNext: false,
      ),
      meetingKeys: const [1],
    );
  }
}

class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError('No network calls should be made in tests.');
  }
}
