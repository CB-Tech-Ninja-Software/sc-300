class ChecklistItem {
  final String id;
  final String title;
  final String detail;

  const ChecklistItem({required this.id, required this.title, required this.detail});
}

class ChecklistItems {
  static const List<ChecklistItem> items = [
    ChecklistItem(
      id: "onvue_system_test",
      title: "Pearson VUE OnVUE system test completed",
      detail: "Run the OnVUE system test on the exact machine, webcam, and internet connection you will use on exam day.",
    ),
    ChecklistItem(
      id: "government_id",
      title: "Valid government-issued photo ID ready",
      detail: "Have your unexpired passport, driver's license, or national ID ready. The name must match your Microsoft certification profile exactly.",
    ),
    ChecklistItem(
      id: "clear_workspace",
      title: "Private room and clear desk prepared",
      detail: "Ensure your room is quiet and private. Clear your desk of extra monitors, papers, books, phones, and smart watches.",
    ),
    ChecklistItem(
      id: "stable_network",
      title: "Reliable network & firewalls checked",
      detail: "Use a stable, wired connection if possible. Disable VPNs, third-party firewalls, and corporate security filters that block video streaming.",
    ),
    ChecklistItem(
      id: "webcam_mic",
      title: "Webcam and microphone verified",
      detail: "Confirm your webcam can be repositioned to show your desk/room during check-in, and your microphone transmits clear audio.",
    ),
    ChecklistItem(
      id: "login_ready",
      title: "Microsoft Learn / Pearson credentials handy",
      detail: "Know your Microsoft certification account login credentials. Password autofill may be disabled inside the secure browser.",
    ),
    ChecklistItem(
      id: "phone_placement",
      title: "Mobile phone ready for check-in photos",
      detail: "Use your phone to photograph your ID and testing room during check-in, then place it on silent out of arm's reach.",
    ),
    ChecklistItem(
      id: "appointment_confirmed",
      title: "Exam appointment time confirmed",
      detail: "Double-check your confirmation email for the exact check-in window (usually 30 minutes before the scheduled start time).",
    ),
  ];
}
