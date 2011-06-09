function run_unit_test(test_name)
%RUN_UNIT_TEST   Run an Mlunit unit test.
%
%  run_unit_test(test_name)

clear(test_name)

runner = mlunit.text_test_runner(1,1);
loader = mlunit.test_loader;
run(runner, load_tests_from_test_case(loader, test_name));


