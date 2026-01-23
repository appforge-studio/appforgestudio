import sourceMapSupport from "source-map-support";
sourceMapSupport.install();
import app from "../src/app";
import adminCreateComponent from "./../src/procedures/admin/create_component.rpc";
import adminCreateType from "./../src/procedures/admin/create_type.rpc";
import adminGetComponents from "./../src/procedures/admin/get_components.rpc";
import adminGetTypes from "./../src/procedures/admin/get_types.rpc";
import adminSaveTypeCode from "./../src/procedures/admin/save_type_code.rpc";
import adminUpdateComponent from "./../src/procedures/admin/update_component.rpc";
import adminUpdateTypeDefinition from "./../src/procedures/admin/update_type_definition.rpc";
import aiGenerateDesign from "./../src/procedures/ai/generate_design.rpc";
import aiGenerateImage from "./../src/procedures/ai/generate_image.rpc";
import aiIterateDesign from "./../src/procedures/ai/iterate_design.rpc";
import svgGetSvgs from "./../src/procedures/svg/get_svgs.rpc";

app.rpc("admin.create_component", adminCreateComponent);
app.rpc("admin.create_type", adminCreateType);
app.rpc("admin.get_components", adminGetComponents);
app.rpc("admin.get_types", adminGetTypes);
app.rpc("admin.save_type_code", adminSaveTypeCode);
app.rpc("admin.update_component", adminUpdateComponent);
app.rpc("admin.update_type_definition", adminUpdateTypeDefinition);
app.rpc("ai.generate_design", aiGenerateDesign);
app.rpc("ai.generate_image", aiGenerateImage);
app.rpc("ai.iterate_design", aiIterateDesign);
app.rpc("svg.get_svgs", svgGetSvgs);

export default app;
