function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'images', 'pipeline_images');
end
obj = schemaObject;
end
