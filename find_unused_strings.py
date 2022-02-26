import argparse
import logging
import os
import sys
import json
from typing import Set
from typing import Dict
from typing import List
from pathlib import Path
import re
import unittest

def main(argv):
  logging.getLogger().setLevel(logging.INFO)

  parser = argparse.ArgumentParser(
    description='Find unused strings')
  parser.add_argument('--strings-file', default='lib/l10n/app_en.arb')
  parser.add_argument('--project-root', default='.')
  parser.add_argument('--ignored-prefixes', nargs='*', default=['ios_NS', 'app_markets'])
  parser.add_argument('--fail-if-found', action='store_true')
  options = parser.parse_args()

  strings_used_in_code = extract_strings_from_dir_recursive(options.project_root)
  declared_strings = extract_declared_dart_strings_from_file(options.strings_file)
  difference = declared_strings.difference(strings_used_in_code)

  ignored_prefixes = list(options.ignored_prefixes) + ['@']
  def should_ignore(string: str):
    return any(map(lambda prefix: string.startswith(prefix), ignored_prefixes))
  difference = set(filter(lambda string: should_ignore(string) is False, difference))

  if difference:
    print('Unused strings:')
    for string in difference:
      print('  {}'.format(string))
    if options.fail_if_found:
      sys.exit('ERROR: Found unused Flutter strings')

def extract_strings_from_str(string: str):
  result = set()
  result.update(re.findall('context\.strings\.(\w+)', string))

  complex_result = re.findall('context\.strings( |\t)*\n( |\t)*\.(\w+)', string)
  result.update(map(lambda tuple: tuple[2], complex_result))

  complex_result = re.findall('context( |\t)*\n( |\t)*\.strings\.(\w+)', string)
  result.update(map(lambda tuple: tuple[2], complex_result))

  return result

def extract_strings_from_file(file_path: str):
  file_content = None
  with open(file_path, 'r', encoding='utf-8') as f:
    file_content = f.read(file_content)
  return extract_strings_from_str(file_content)

def extract_strings_from_dir_recursive(dir_path: str, acceptable_files='.*\.dart$'):
  result = set()
  for path, subdirs, files in os.walk(dir_path):
    for name in files:
      if not re.match(acceptable_files, name):
        continue
      result.update(extract_strings_from_file(os.path.join(path, name)))
  return result

def extract_declared_dart_strings_from_file(file_path: str):
  strings = None
  with open(file_path, 'r', encoding='utf-8') as f:
    strings = json.load(f)
  return set(strings.keys())


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))


class MainTests(unittest.TestCase):
  def test_extract_strings_from_str(self):
    string = '''
      shopsManager.verity_createShop_called(times: 0);
      await tester.superTap(find.text(context.strings.global_done));
      expect(find.byType(MapPage), findsNothing);

      ...

      Text(
        context.strings
            .display_product_page_veg_status_possible_explanation,
        style: TextStyles.normal)

      ...

      Text(
          context
              .strings.edit_user_data_widget_avatar_description,
          style: TextStyles.normalColored
              .copyWith(color: ColorsPlante.grey))
    '''

    result = extract_strings_from_str(string)
    expected_result = {
      'global_done',
      'display_product_page_veg_status_possible_explanation',
      'edit_user_data_widget_avatar_description',
    }
    self.assertEqual(expected_result, result)

  def test_extract_strings_from_file(self):
    file_content = '''
      shopsManager.verity_createShop_called(times: 0);
      await tester.superTap(find.text(context.strings.global_done));
      expect(find.byType(MapPage), findsNothing);
    '''

    file_path = '/tmp/test_extract_strings_from_file'
    with open(file_path, 'w', encoding='utf-8') as f:
      f.write(file_content)
    
    result = extract_strings_from_file(file_path)
    expected_result = {
      'global_done',
    }
    self.assertEqual(expected_result, result)

  def test_extract_strings_from_dir_recursive(self):
    Path('/tmp/test_extract_strings_from_dir_recursive/1/2').mkdir(parents=True, exist_ok=True)


    file_content = '''
      shopsManager.verity_createShop_called(times: 0);
      await tester.superTap(find.text(context.strings.{}));
      expect(find.byType(MapPage), findsNothing);
    '''

    with open('/tmp/test_extract_strings_from_dir_recursive/code.dart', 'w', encoding='utf-8') as f:
      f.write(file_content.format('global_done1'))
    with open('/tmp/test_extract_strings_from_dir_recursive/not_code.not_dart', 'w', encoding='utf-8') as f:
      f.write(file_content.format('global_done2'))
    with open('/tmp/test_extract_strings_from_dir_recursive/1/code.dart', 'w', encoding='utf-8') as f:
      f.write(file_content.format('global_done3'))
    with open('/tmp/test_extract_strings_from_dir_recursive/1/2/code.dart', 'w', encoding='utf-8') as f:
      f.write(file_content.format('global_done4'))
    
    result = extract_strings_from_dir_recursive('/tmp/test_extract_strings_from_dir_recursive/')
    expected_result = {
      'global_done1',
      'global_done3',
      'global_done4',
    }
    self.assertEqual(expected_result, result)

  def test_extract_declared_dart_strings_from_file(self):
    file_content = '''
      {
        "veg_status_selection_panel_dunno": "Not sure",
        "veg_status_selection_panel_negative": "No",
        "veg_status_selection_panel_positive": "Yes"
      }
    '''

    file_path = '/tmp/test_extract_declared_dart_strings_from_file'
    with open(file_path, 'w', encoding='utf-8') as f:
      f.write(file_content)
    
    result = extract_declared_dart_strings_from_file(file_path)
    expected_result = {
      'veg_status_selection_panel_dunno',
      'veg_status_selection_panel_negative',
      'veg_status_selection_panel_positive',
    }
    self.assertEqual(expected_result, result)
