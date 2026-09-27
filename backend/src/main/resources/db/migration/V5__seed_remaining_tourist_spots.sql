-- Coordinates supplied by project owner; radii are application geofences, not official boundaries.

WITH seed(
    name,
    description,
    latitude,
    longitude,
    radius_meters,
    address,
    aliases
) AS (
 VALUES
 (
   'Devghat',
   'River-confluence pilgrimage and visitor area.',
   27.741110,
   84.423330,
   1000,
   'Devghat, Chitwan–Tanahun area, Nepal',
   ARRAY['devghat']
 ),
 (
   'Patihani / Umbrella Street tourist area',
   'Patihani visitor area including Umbrella Street.',
   27.580330,
   84.361960,
   1000,
   'Patihani, Bharatpur, Chitwan, Nepal',
   ARRAY[
     'patihani',
     'umbrella street',
     'patihani / umbrella street tourist area'
   ]
 ),
 (
   'Meghauli tourist area',
   'Visitor area around Meghauli.',
   27.580289,
   84.226796,
   1200,
   'Meghauli, Bharatpur, Chitwan, Nepal',
   ARRAY[
     'meghauli',
     'meghauli tourist area'
   ]
 ),
 (
   'Golaghat / Rapti-Narayani Confluence',
   'River-confluence viewing and visitor area.',
   27.563890,
   84.158060,
   1000,
   'Golaghat, Bharatpur, Chitwan, Nepal',
   ARRAY[
     'golaghat',
     'golaghat river-confluence area',
     'golaghat / rapti-narayani confluence'
   ]
 ),
 (
   'Tikauli Jungle area',
   'Forest and nature visitor area around Tikauli.',
   27.632360,
   84.501420,
   1200,
   'Tikauli, Chitwan, Nepal',
   ARRAY[
     'tikauli jungle',
     'tikauli jungle area'
   ]
 ),
 (
   'Sauraha tourist area',
   'Sauraha visitor area near the Rapti riverfront.',
   27.577900,
   84.494500,
   1200,
   'Sauraha, Ratnanagar, Chitwan, Nepal',
   ARRAY[
     'sauraha',
     'sauraha tourist area',
     'sauraha tourist area / rapti riverfront'
   ]
 ),
 (
   'Khorsor / Elephant Breeding Center',
   'Elephant Breeding Center visitor attraction at Khorsor.',
   27.581470,
   84.475420,
   700,
   'Khorsor, near Sauraha, Chitwan, Nepal',
   ARRAY[
     'khorsor / elephant breeding center',
     'elephant breeding center, khorsor'
   ]
 ),
 (
   'Kasara / Chitwan National Park visitor area',
   'Kasara visitor area associated with Chitwan National Park.',
   27.550110,
   84.331590,
   1000,
   'Kasara, Chitwan, Nepal',
   ARRAY[
     'kasara',
     'kasara / chitwan national park visitor area',
     'kasara / chitwan national park visitor entrance'
   ]
 )
)
INSERT INTO tourist_spots (
    name,
    description,
    latitude,
    longitude,
    radius_meters,
    address,
    active,
    created_at,
    updated_at
)
SELECT
    seed.name,
    seed.description,
    seed.latitude,
    seed.longitude,
    seed.radius_meters,
    seed.address,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM seed
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots spot
    WHERE lower(trim(spot.name)) = ANY(seed.aliases)
       OR (
         spot.latitude = seed.latitude
         AND spot.longitude = seed.longitude
       )
);-- Placeholder: paste the contents of backend/src/main/resources/db/migration/V5__seed_remaining_tourist_spots.sql from your app here.
