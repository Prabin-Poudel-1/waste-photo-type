-- Coordinates and radii supplied by the project owner.
-- Radii are application matching values, not official geographic boundaries.
-- Preserve existing records, including inactive or manually configured destinations.

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
      'Narayani Riverside / Narayani River Park',
      'Riverfront visitor area beside the Narayani River. Application matching radius: 800 metres.',
      27.699570,
      84.422010,
      800,
      'Narayani riverside, Bharatpur, Chitwan, Nepal',
      ARRAY[
        'narayani riverside / narayani river park',
        'narayani riverside',
        'narayani river park',
        'narayani riverbank'
      ]
    ),
    (
      'Bishazari Tal (Beeshazar and Associated Lakes)',
      'Lake and nature destination. Application matching radius: 1800 metres.',
      27.617500,
      84.438700,
      1800,
      'Bishazari Tal, Chitwan, Nepal',
      ARRAY[
        'bishazari tal (beeshazar and associated lakes)',
        'bishazari tal',
        'beeshazar and associated lakes',
        'beeshazar tal',
        'bis hazari tal'
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
);