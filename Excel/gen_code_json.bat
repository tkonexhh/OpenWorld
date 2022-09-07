set WORKSPACE=..

set GEN_CLIENT=%WORKSPACE%\Tools\LuBan\Tools\Luban.ClientServer\Luban.ClientServer.exe
set CONF_ROOT=%WORKSPACE%\Excel

%GEN_CLIENT% -j cfg --^
 -d %CONF_ROOT%\Defines\__root__.xml ^
 --input_data_dir %CONF_ROOT%\Datas ^
 --output_code_dir %WORKSPACE%\UnityProject\OpenWorld\Assets\Scripts\Table\Generate ^
 --output_data_dir %WORKSPACE%\UnityProject\OpenWorld\GenerateDatas\json ^
 --gen_types code_cs_unity_json,data_json ^
 -s all 

pause