Feature: File creation
  In order maintain a universal mode of creating files
  I should be able to create a file using any adapter
  
  Scenario: UFS::FS file creation
    Given I am using the UFS::FS adapter
    When I touch /tmp/test.txt
    Then /tmp/test.txt should exist
    And I should be able to destroy /tmp/test.txt