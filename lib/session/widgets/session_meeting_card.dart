import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';

class SessionMeetingCard extends StatelessWidget {
  final MeetingData data;

  const SessionMeetingCard({super.key, required this.data});

  String _formatDate(Session s) {
    if (s.dateStart == null) return "N/A";
    final dt = s.dateStart!.toLocal();
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final practice = <Session>[];
    final qualifying = <Session>[];
    final race = <Session>[];

    for (var s in data.sessions) {
      final name = s.sessionName.toLowerCase();
      if (name.contains('practice')) {
        practice.add(s);
      } else if (name.contains('qualifying') || name.contains('shootout')) {
        qualifying.add(s);
      } else if (name.contains('race') || name.contains('sprint')) {
        race.add(s);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Text(
            '${data.meetingInfo.circuitShortName} - ${data.meetingInfo.countryName} (${data.meetingInfo.year})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // BODY
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 800;

              if (isWideScreen) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildGroupCard('Practice', practice)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGroupCard('Qualifying', qualifying)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGroupCard('Race', race)),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * 0.85, 
                          child: _buildGroupCard('Practice', practice),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: constraints.maxWidth * 0.85,
                          child: _buildGroupCard('Qualifying', qualifying),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: constraints.maxWidth * 0.85,
                          child: _buildGroupCard('Race', race),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String title, List<Session> sessions) {
    const cardBgColor = Color(0xFF0F151F);
    const borderColor = Colors.white10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session',
            style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (sessions.isEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, style: BorderStyle.none),
                  color: Colors.white.withValues(alpha: .02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No $title data',
                    style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 12),
                  ),
                ),
              ),
            )
          else
            Column( 
              children: sessions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: .05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.sessionName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(s),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }
}