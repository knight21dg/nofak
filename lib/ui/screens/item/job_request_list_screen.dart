import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/fetch_job_requests_cubit.dart';
import 'package:nofak/data/cubits/manage_job_request_cubit.dart';
import 'package:nofak/data/model/user/job_request_model.dart';
import 'package:nofak/ui/screens/widgets/errors/no_data_found.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/utils/widgets.dart';

class JobRequestsListScreen extends StatefulWidget {
  const JobRequestsListScreen({super.key});

  @override
  State<JobRequestsListScreen> createState() => _JobRequestsListScreenState();

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const JobRequestsListScreen(),
    );
  }
}

class _JobRequestsListScreenState extends State<JobRequestsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  String _currentRole = "user"; // "user" or "technician"
  String? _selectedStatus;

  final List<String> _statuses = [
    "all",
    "pending",
    "accepted",
    "in_progress",
    "completed",
    "cancelled",
    "rejected"
  ];

  @override
  void initState() {
    super.initState();
    final isTechnician = HiveUtils.getUserDetails().fieldOfExpertise != null;
    _currentRole = isTechnician ? "technician" : "user";

    _tabController = TabController(
      length: isTechnician ? 2 : 1,
      vsync: this,
    );

    _tabController.addListener(() {
      setState(() {
        _currentRole = _tabController.index == 0 && isTechnician
            ? "technician"
            : "user";
      });
      _fetchJobs();
    });

    _scrollController = ScrollController()..addListener(_loadMore);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchJobs() {
    context.read<FetchJobRequestsCubit>().fetchJobRequests(
          role: _currentRole,
          status: _selectedStatus == "all" ? null : _selectedStatus,
        );
  }

  void _loadMore() {
    if (_scrollController.isEndReached()) {
      if (context.read<FetchJobRequestsCubit>().hasMoreData()) {
        context.read<FetchJobRequestsCubit>().fetchMoreJobRequests(
              role: _currentRole,
              status: _selectedStatus == "all" ? null : _selectedStatus,
            );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRatingDialog(JobRequestModel job) {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Rate Technician"),
          content: StatefulBuilder(
            builder: (context, setStater) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText("Rate your experience:"),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStater(() {
                            rating = index + 1;
                          });
                        },
                        child: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write a review (optional)...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                      jobId: job.id!,
                      status: "completed",
                      rating: rating,
                      review: reviewController.text.trim(),
                    );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTechnician = HiveUtils.getUserDetails().fieldOfExpertise != null;

    return BlocListener<ManageJobRequestCubit, ManageJobRequestState>(
      listener: (context, state) {
        if (state is ManageJobRequestInProgress) {
          LoadingWidgets.showLoader(context);
        } else {
          LoadingWidgets.hideLoader(context);
        }

        if (state is ManageJobRequestUpdateSuccess) {
          HelperUtils.showSnackBarMessage(context, "Status updated successfully.");
          _fetchJobs();
        }

        if (state is ManageJobRequestFailure) {
          HelperUtils.showSnackBarMessage(context, state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.color.secondaryColor,
          title: CustomText("Job Requests".translate(context).isEmpty
              ? "Inspection Jobs"
              : "Job Requests".translate(context), fontWeight: FontWeight.bold),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.color.textDefaultColor),
          ),
          bottom: isTechnician
              ? TabBar(
                  controller: _tabController,
                  indicatorColor: context.color.territoryColor,
                  labelColor: context.color.territoryColor,
                  unselectedLabelColor: context.color.textDefaultColor.withValues(alpha: 0.6),
                  tabs: const [
                    Tab(text: "Received Jobs"),
                    Tab(text: "Hired Jobs"),
                  ],
                )
              : null,
        ),
        body: Column(
          children: [
            statusFilterBar(),
            Expanded(child: jobsListView()),
          ],
        ),
      ),
    );
  }

  Widget statusFilterBar() {
    return Container(
      height: 48,
      color: context.color.secondaryColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = (_selectedStatus == status) ||
              (_selectedStatus == null && status == "all");

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = status == "all" ? null : status;
                });
                _fetchJobs();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? context.color.territoryColor : context.color.backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? context.color.territoryColor : context.color.borderColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : context.color.textDefaultColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget jobsListView() {
    return BlocBuilder<FetchJobRequestsCubit, FetchJobRequestsState>(
      builder: (context, state) {
        if (state is FetchJobRequestsInProgress) {
          return Center(child: UiUtils.progress());
        }

        if (state is FetchJobRequestsFailure) {
          return Center(child: CustomText(state.errorMessage));
        }

        if (state is FetchJobRequestsSuccess) {
          if (state.jobs.isEmpty) {
            return Center(
              child: NoDataFound(
                onTap: _fetchJobs,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  itemCount: state.jobs.length,
                  itemBuilder: (context, index) {
                    final job = state.jobs[index];
                    return jobCard(job);
                  },
                ),
              ),
              if (state.isLoadingMore) UiUtils.progress(),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget jobCard(JobRequestModel job) {
    // Other party details
    final otherUser = _currentRole == "user" ? job.technician : job.user;
    final otherName = otherUser?.name ?? "Specialist";
    final otherProfile = otherUser?.profile ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: otherProfile.isNotEmpty ? NetworkImage(otherProfile) : null,
                  child: otherProfile.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(otherName, fontWeight: FontWeight.bold),
                      if (_currentRole == "user" && job.technician?.fieldOfExpertise != null)
                        CustomText(
                          job.technician!.fieldOfExpertise!,
                          fontSize: context.font.smaller,
                          color: context.color.territoryColor,
                        ),
                      if (_currentRole == "technician")
                        CustomText(
                          "Hired by client",
                          fontSize: context.font.smaller,
                          color: context.color.textLightColor,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    job.status!.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(job.status!),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  job.description ?? "",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: context.color.textLightColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        job.address ?? "No address specified",
                        fontSize: context.font.small,
                        color: context.color.textLightColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (job.proposedFee != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.payments_rounded, size: 14, color: context.color.textLightColor),
                      const SizedBox(width: 4),
                      CustomText(
                        "Proposed Fee: ${job.proposedFee!.toStringAsFixed(2)}",
                        fontSize: context.font.small,
                        color: context.color.textLightColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Action Buttons
          if (hasActions(job)) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actionButtons(job),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool hasActions(JobRequestModel job) {
    final status = job.status!.toLowerCase();
    if (_currentRole == "technician") {
      return status == "pending" || status == "accepted" || status == "in_progress";
    } else {
      return status == "pending" || (status == "completed" && job.rating == null);
    }
  }

  List<Widget> actionButtons(JobRequestModel job) {
    final status = job.status!.toLowerCase();
    List<Widget> buttons = [];

    if (_currentRole == "technician") {
      if (status == "pending") {
        buttons.add(
          TextButton(
            onPressed: () {
              context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                    jobId: job.id!,
                    status: "rejected",
                  );
            },
            child: const CustomText("Reject", color: Colors.red),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.color.territoryColor),
            onPressed: () {
              context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                    jobId: job.id!,
                    status: "accepted",
                  );
            },
            child: const CustomText("Accept", color: Colors.white),
          ),
        );
      } else if (status == "accepted") {
        buttons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.color.forthColor),
            onPressed: () {
              context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                    jobId: job.id!,
                    status: "in_progress",
                  );
            },
            child: const CustomText("Start Job", color: Colors.white),
          ),
        );
      } else if (status == "in_progress") {
        buttons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                    jobId: job.id!,
                    status: "completed",
                  );
            },
            child: const CustomText("Complete Job", color: Colors.white),
          ),
        );
      }
    } else {
      if (status == "pending") {
        buttons.add(
          TextButton(
            onPressed: () {
              context.read<ManageJobRequestCubit>().updateJobRequestStatus(
                    jobId: job.id!,
                    status: "cancelled",
                  );
            },
            child: const CustomText("Cancel Request", color: Colors.red),
          ),
        );
      } else if (status == "completed" && job.rating == null) {
        buttons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () => _showRatingDialog(job),
            child: const CustomText("Submit Review", color: Colors.white),
          ),
        );
      }
    }

    return buttons;
  }
}
