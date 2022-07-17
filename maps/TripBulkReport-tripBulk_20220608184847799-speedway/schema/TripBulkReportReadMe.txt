*** TripBulkReport ReadMe.txt ***

The TripBulkReport is a .zip archive containing data files and associated schema files.

The files in the /data folder include:

- trips.csv - contains trips with metadata such as start/end location, start/end time, provider id, device id, origin/destination zone, trip length, and other fields.

- waypoints.csv - contains full GPS waypoint data, listed trip by trip

- through.csv - for every trip, this file lists every zone intersected in a two-column format; this file is only provided if through trips (also known as EE (external-external) trips) were requested, since origin/destination zone info is always present in trips.csv.

- trajectories.csv - contains trajectories metadata by trip

- corridors.csv - contains trip corridor associations and corridor travel time metrics

The files in the /schema folder (all prefixed by TripBulkReport) include:

-TripsHeaders.csv - contains column names for trips.csv

-WaypointsHeaders.csv - contains column names for waypoints.csv (if waypoints are requested)

-ThroughHeaders.csv - contains column names for through.csv (if through trips are requested)

-TrajectoriesHeaders.csv - contains column names for trajectories.csv (if trajectories are requested)

-CorridorLinkAnalysisHeaders - contains column names for corridors.csv (if corridor link analysis is requested)

-ProviderDetails.csv - contains additional metadata about all INRIX providers; this is not limited to the providers present in the current report.

-ProviderDetailsHeaders.csv - contains column names for ProviderDetails.csv

-TripBulkReportDefinition.json - [for INRIX reference - contains the internal report definition including deprecated parameters.]

Column definitions for the schema files are described below.

*** TripsHeaders.csv - Column Definitions ***

Non-Anonymized Output:

TripID - A trip's unique identifier
DeviceID - A device's unique identifier
ProviderID - A provider's unique identifier
Mode - The mode of travel (0=Walk, 1=Vehicle, 2=Unknown)
StartDate - The trip's start date and time in UTC, ISO-8601 format, example: "2014-04-01T08:33:35.000Z"
StartWDay - The trip's start weekday in local time, where 1=Mon, 2=Tues, 3=Wed, 4=Thurs, 5=Fri, 6=Sat, 7=Sun
EndDate - The trip's end date and time in UTC, ISO-8601 format, example: "2014-04-01T08:33:35.000Z"
EndWDay - The trip's end weekday in local time, where 1=Mon, 2=Tues, 3=Wed, 4=Thurs, 5=Fri, 6=Sat, 7=Sun
StartLocLat - The latitude coordinates of the trip's start point in decimal degrees
StartLocLon - The longitude coordinates of the trip's start point in decimal degrees
EndLocLat - The latitude coordinates of the trip's end point in decimal degrees
EndLocLon - The decimal degree longitude coordinates of the trip's end point in decimal degree
GeospatialType - describes the trip's geospatial intersection with the requested zones (II - Internal-to-Internal: trips that start & end within any zones; IE - Internal-to-External: trips that start within any zone and end outside of any zone; EI - External-to-Internal: trips that start outside of any zone and end within in any zone; EE - External-to-External: trips that start & end outside of any zones, but were selected because of an intersection with one or more zones)
ProviderType - Numeral representing the provider type (Consumer, Fleet, Mobile)
DrivingProfile - Numeral representing the provider driving profile
VehicleWeightClass - Numeral representing the vehicle weight class
ProbeSourceType - Numerall representing the probe source type
OriginZoneName - The origin zone of the trip, if the trip started in a zone
DestinationZoneName - The destination zone of the trip, if the trip started in a zone
EndpointType - Indicates if the trip starts and ends in a detected stop (blank=unknown (prior to 2017), -1 = Unknown, 0 = Trip does not start or end at stop, 1 = Trip starts at stop, 2 = Trip ends at stop, 3 = Trip starts and ends at stop)
TripMeanSpeedKph - The mean speed of the trip, in kph
TripMaxSpeedKph - The max speed of the trip, in kph
TripDistanceM - Trip distance in meters
MovementType - 1 = Moving Trip, 0 = Non-moving Trip
OriginCensusBlockGroup - Census Block Group of origin (US only)
DestinationCensusBlockGroup - Census Block Group of destination (US only)
StartTimezone - Timezone of the trip's start coordinate
EndTimezone - Timezone of the trip's end coordinate
WaypointFreqSeconds - Waypoint frequency of the trip in seconds
StartQuadkey - The level 18 quadkey corresponding to the trip's start coordinate at a resolution of up to 300 meters
EndQuadkey - The level 18 quadkey corresponding to the trip's end coordinate at a resolution of up to 300 meters
CustomAttrs - Custom attributes associated with the trip

*** WaypointsHeaders.csv - Column Definitions ***

TripID - A trip's unique identifier
WaypointSequence - The order of the waypoint within the trip starting with "1" and incrementing by one
CaptureDate - The capture date and time of the waypoint in UTC, ISO-8601 format, example: "2014-04-01T08:33:35.000Z"
Latitude - The decimal degree latitude coordinates of the waypoint
Longitude - The decimal degree longitude coordinates of the waypoint
SegmentID - Populated if "includeTrajectories" was specified, this represents the segment ID snapped to a trip's waypoint.
 Note: In conflation scenario (ie  "enableSegmentConflation" = true), SegmentID will be unpopulated.
ZoneName -  Populated if the "includeZones" flag was enabled, represents the zone, if available, for which any waypoint intersects
FRC - [deprecated - do not use]
DeviceId - A device's unique identifier
RawSpeed - Provider Raw speed (populated if supplied by provider)
RawSpeedMetric - Raw speed metric
CustomAttrs - Custom attributes associated with the waypoint

*** ThroughHeaders.csv - Column Definitions ***
TripID - A trip's unique identifier
ZoneName - represents the zone, if available, for which any waypoint intersects

*** TrajectoriesHeaders.csv - Column Definitions ***
TripID - A trip's unique identifier
DeviceID - A device's unique identifier
ProviderID - Provider's unique identifier
TimeZone - Trip's start timezone
TrajIdx - Index of a trajectory for this trip. For very sparse point spacing in time and distance, it may not be possible to accurately map match the vehicle's trajectory.
 In this case, points are split and multiple trajectories created out of a single trip. The trajectory index is sequenced in travel order.
TrajRawDistanceM - Cumulative distance of raw points in meters relative to start of trajectory
TrajRawDurationMillis - Cumulative duration of raw points in milliseconds relative to start of trajectory
SegmentId - Segment ID of the road section on the map. For the OSM map, the segment ID includes a minus sign to indicate directionality
SegmentIdx - Index of a segment within a trajectory
LengthM - Length of segment in meters
CrossingStartOffsetM - Start offset in meters relative to the start of the segment where a device enters this segment
CrossingEndOffsetM - End offset in meters relative to the start of the segment where a device leaves this segment
CrossingStartDateUtc - Start date in in ISO 8601 format when a device enters this segment
CrossingEndDateUtc - End date in in ISO 8601 format when a device leaves this segment
CrossingSpeedKph - The segment crossing speed in kph
OnRoadSnapCount - The count of snapped points on this segment which are on the road network
ErrorCodes - List of error codes associated with this segment
      100 => SegmentOffRoad
      101 => SegmentCrossingSpeedExceedsMax (>250 kph)
      102 => SegmentCrossingSpeedToRawExceeded (>200%)
      103 => SegmentCrossingSpeedBelowMin (<0 kph)
      104 => SegmentCrossingDistanceBelowMin (<1 meter)

The following attributes are populated only if the "includeSnaps" option was enabled:
PointId - Id of a point relative to the original waypoints in the trip. Same as WaypointSequence.
SnappedLat - Latitude for the point on the nearest OSM segment
SnappedLon - Longitude for the point on the nearest OSM segment
DateUtc - UTC Date Time String in ISO 8601 format.  Example: "2014-04-01T08:33:35.000Z"

OffsetM - Offset of the snapped point to the start of the segment. Values are represented in meters.
Heading - The Heading/Direction in degrees at the moment when the GPS measurement was made. The acceptable values are in the range of 0-360.
HeadingOffset - Heading offset of the raw point compared to the heading of the snapped point
ProximityM - Distance from the raw lat/lon to the snapped lat/lon. Values are represented in meters.
Confidence - Confidence in the match of the raw point to the closest point on the specified map segment.
             Values range from 1 (highly unlikely) to 100 (highly likely).   The confidence value is based on the frequency with which a point with similar heading offset and proximity is deemed to be correct.
IsOnRoadNetwork - Whether a point is on the road network
IsResnapped - Whether a point is resnapped to the road network (Internal use only)
RawLat - Latitude of raw GPS point (included if both "includeSnaps" and "includeRaw" options were enabled)
RawLon - Longitude of raw GPS point (included if both "includeSnaps" and "includeRaw" options were enabled)

*** CorridorLinkAnalysisHeaders.csv - Column Definitions ***
TripID - A trip's unique identifier
TripDistanceM - Trip distance in meters
TripDurationSec - Trip duration in seconds
ProviderType - Provider type
CorridorId - Identifier for the corridor
CorridorName - Corridor name
TravelTimeSec - Corridor travel time in seconds
StartUtc - Corridor start epoch timestamp in milliseconds
StartDateLocal - Corridor local date time in ISO 8601 format
TrajIdx - Index of trajectory corresponding to this corridor
StartSegmentIdx - Index of first segment in the trajectory matching this corridor
EndSegmentIdx - Index of last segment in the trajectory matching this corridor
StartSegmentOffsetM - Start offset of start of the corridor relative to the first segment in the trajectory matching this corridor
EndSegmentOffsetM - End offset of end of the corridor relative to the last segment in the trajectory matching this corridor
DrivingProfile - Numeral representing the provider driving profile
VehicleWeightClass - Numeral representing the vehicle weight class
ProbeSourceType - Numeral representing the probe source type

*** ProviderDetails.csv - Column Definitions ***

ProviderId - A provider's unique identifier
ProviderType - Describes the provider type
    1 = Consumer
    2 = Fleet
ProviderDrivingProfile -  Driving class, additional detail about type of provider
    1 = Consumer Vehicles
    2 = Taxi/shuttle/town car services
    3 = Field Service/Local Delivery Fleets
    4 = For hire/private trucking fleets
VehicleWeightClass - Lists one of three weight classes provider
    1 = Light Duty Truck/Passenger Vehicle: Ranges from 0 to 14,000 lb.
    2 = Medium Duty Trucks / Vans: ranges from 14001–26000 lb.
    3 = Heavy Duty Trucks: > 26000 lb.
ProbeSourceType - Device type
    1 = Embedded GPS
    2 = Mobile Device

If the trip matrix summary option is enabled, the following files are provided in the matrix/ folder:

-TripMatrixReport.csv - Contains summary counts of trips grouped by origin and destination zones.
-TripMatrixHeaders.csv - Header file for the TripMatrixReport should the user wish to utilize them.

If gespatialMatchOn = "EE" is specified:
-ThroughMatrixReport.csv - Contains summary counts of zone crossings by trips.
-ThroughMatrixReportHeaders.csv - Header file for the ThroughMatrixReport should the user wish to utilize them.

Column definitions for the data files are described below.

*** TripMatrixReport - Column Definitions ***

-OriginZoneName - Name of the trip's origin zone. If outside the provided input zones, the value is "external".
-DestinationZoneName - Name of the trip's destination zone. If outside the provided input zones, the value is "external".
-NumberOfTrips - Count of trips starting in origin zone, and ending in destination zone.
-PercentageOfTrips - Percentage trips starting in origin zone, and ending in destination zone relative to the total trip count included in this file.

*** ThroughMatrixReport - Column Definitions ***

-ZoneName - Name of the zone.
-GeospatialType - Value is "EE" (External to External)
-NumberOfTrips - Count of trips crossing the zone. This does not include trips which start or ended any of the input zones.
-PercentageOfTrips - Percentage trips crossing the zone relative to the total count of trip crossings included in this file.

###

FAQs

1. Are there header rows in the Data?
	No, header rows are not included in the data files, but are provided as separate .csv files should the user wish to utilize them.
	 (TripBulkReportProviderDetailsHeaders, TripBulkReportWaypointsHeaders, TripBulkReportTripsHeaders, TripBulkReportTripLinkAnalysisHeaders, TripBulkReportTripLinkCorridorSegmentsHeaders)
2. What is the date format in the report output?
    All dates are represented in UTC ISO-8601 format, example: "2014-04-01T08:33:35.000Z"

###