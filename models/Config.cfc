component extends="cborm.models.ActiveEntity" persistent="true" table="config" output="false" {
	property name="bootstrapped" ormtype="tinyint" fieldtype="id";
	property name="created_date" column="created_date" fieldtypep="timestamp";
}
			