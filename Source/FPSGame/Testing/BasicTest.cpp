#include "Misc/AutomationTest.h"

// EditorContext defines that we want to be able to run this test in the Editor
// ProductFilter is for defining how long the test will take to run
// For more information check AutomationTest.h
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FBasicExampleTest, "FPSGameTests.Basic", EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

// Your function must be named RunTest
// The struct name here "FBasicExampleTest" must match the one in the macro above
bool FBasicExampleTest::RunTest(const FString &Parameters)
{
	return TestTrue("math still works", 1 < 2);
}