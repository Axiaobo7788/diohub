import 'package:diohub_graphql/queries/support/support_listing_tiers.graphql.dart';
import 'package:diohub_graphql/queries/support/support_for_viewer.graphql.dart';

typedef SupportTiersData = Query$supportListingTiers;
typedef SupportListing = Query$supportListingTiers$user$sponsorsListing;
typedef SupportTierNode = Query$supportListingTiers$user$sponsorsListing$tiers$nodes;
typedef SupportForViewerData = Query$supportForViewer;
typedef SupportForViewerSponsorship = Query$supportForViewer$user$sponsorshipForViewerAsSponsor;
