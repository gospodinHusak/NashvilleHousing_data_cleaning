-- Looking at the data

SELECT * 
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-- There are several things that we may do to improve the usage of the data. Columns "PropertyAddress" and "OwnerAddress" have so much data in one cell, that we could split for some special querrying

-----------

-- Before splitting the data from Property Address let's try to fill missing values.
-- While examining the data, it turned out that in cases where the values in the ParcelID column were the same, then the other values were also equal (excluding UniqueID)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing a
JOIN Nashville_Housing_Data_Portfolio_Project..Nashville_Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- So, let's update data to fill NULLs

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing a
JOIN Nashville_Housing_Data_Portfolio_Project..Nashville_Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- In the case of the property owner, the application of this algorithm can lead to inaccuracies, since one house may have different owners with different addresses

-----------

SELECT PropertyAddress
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-- Now, let's split the data from "PropertyAddress" using "SUBSTRING"

ALTER TABLE Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
ADD Property_city NVARCHAR(255),
Property_address NVARCHAR(255)

Update Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
SET Property_city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)),
Property_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

SELECT Property_city, Property_address
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-----------

-- Same with "OwnerAddress", but using "PARSENAME"

SELECT OwnerAddress
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

ALTER TABLE Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
ADD Owner_state NVARCHAR(255),
Owner_city NVARCHAR(255),
Owner_address NVARCHAR(255)


Update Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
SET Owner_state = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
Owner_city = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
Owner_address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

SELECT Owner_state, Owner_city, Owner_address
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-----------

-- Now, let's modify "SaleDate" format, as it has time, which is useless, as it's 00:00:00 in all the cases

SELECT SaleDate
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

ALTER TABLE Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
ADD SaleDate_converted Date


Update Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
SET SaleDate_converted = CONVERT(Date, SaleDate)


SELECT SaleDate_converted
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-----------

-- In "SoldAsVacant" there is 4 values "Y", "N", "Yes" and "No". So, we should unify them for better future usage

UPDATE Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

SELECT SoldAsVacant
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

-----------

-- Now, let's remove duplicates to make the data more accurate

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1

-----------

-- Finally we can get rid of the columns, which are no longer useful to us, because we have made on their basis more convenient ones

SELECT *
FROM Nashville_Housing_Data_Portfolio_Project..Nashville_Housing

ALTER TABLE Nashville_Housing_Data_Portfolio_Project..Nashville_Housing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate