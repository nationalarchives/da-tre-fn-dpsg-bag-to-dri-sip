#!/usr/bin/env python3
import sys
sys.path.append("../../tre-bagit-to-dri-sip")

from tre_bagit import BagitData
from tre_bagit_transforms import dri_config_dict
import csv
import io
import unittest


config_dict = {}
info_dict = {
    "Consignment-Series": "MOCKA 101",
    "Internal-Sender-Identifier": "TDR-2022-AA1",
    "Consignment-Export-Datetime": "2022-07-18T12:45:45Z",
}
manifest_dict = [
    {
        "file": "data/content/file-c1.txt",
        "basename": "file-c1.txt",
        "checksum": "5bd8879fba139fed98c048261cb2a91d727ceafb27414cc54e21c26915e9e40f"  # pragma: allowlist secret
    }
]


def make_bagit(csv_string, replace_folder=False):
    csv_data = csv.DictReader(io.StringIO(csv_string))
    return BagitData(config_dict, info_dict, manifest_dict, csv_data, replace_folder)

# GIVEN a root directory other "content" (e.g. not-content") in the bag
csv_string_v_1_2_not_content = """Filepath,FileName,FileType,Filesize,RightsCopyright,LegalStatus,HeldBy,Language,FoiExemptionCode,LastModified,OriginalFilePath\n""" + \
                   """data/not-content/file-c1.txt,file-c1.txt,File,36,Crown Copyright,Public Record(s),"The National Archives, Kew",English,,2022-09-29T15:10:20,\n""" + \
                   """data/not-content,not-content,Folder,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,,,\n"""


class TestBagitMethods(unittest.TestCase):

    maxDiff = None

    # WHEN generate a SIP using default behaviour (False) of replace_folder
    # THEN closure.csv and metadata.csv have an inserted "content" folder at root

    expected_closure = """identifier,folder,closure_start_date,closure_period,foi_exemption_code,foi_exemption_asserted,title_public,title_alternate,closure_type\n""" + \
                       """file:/MOCKA101Y22TBAA1/MOCKA_101/content/not-content/file-c1.txt,file,,0,open,,TRUE,,open_on_transfer\n""" + \
                       """file:/MOCKA101Y22TBAA1/MOCKA_101/content/,folder,,0,open,,TRUE,,open_on_transfer\n""" + \
                       """file:/MOCKA101Y22TBAA1/MOCKA_101/content/not-content/,folder,,0,open,,TRUE,,open_on_transfer\n"""

    expected_metadata = """identifier,file_name,folder,date_last_modified,checksum,rights_copyright,legal_status,held_by,language,TDR_consignment_ref\n""" + \
                        """file:/MOCKA101Y22TBAA1/MOCKA_101/content/not-content/file-c1.txt,file-c1.txt,file,2022-09-29T15:10:20,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,TDR-2022-AA1\n""" + \
                        """file:/MOCKA101Y22TBAA1/MOCKA_101/content/,content,folder,2022-07-18T12:45:45,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,TDR-2022-AA1\n""" + \
                        """file:/MOCKA101Y22TBAA1/MOCKA_101/content/not-content/,not-content,folder,2022-07-18T12:45:45,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,TDR-2022-AA1\n"""

    def test_bag_1_2_with_non_content_root_to_closure(self):
        bagit = make_bagit(csv_string_v_1_2_not_content)
        dri_config_two = dri_config_dict("TDR-2022-AA1", bagit.consignment_series, bagit.root_folder)
        actual_closure = bagit.to_closure(dri_config_two)
        self.assertEqual(actual_closure, self.expected_closure)

    def test_bag_1_2_with_non_content_root_to_metadata(self):
        bagit = make_bagit(csv_string_v_1_2_not_content)
        dri_config_two = dri_config_dict("TDR-2022-AA1", bagit.consignment_series, bagit.root_folder)
        actual_metadata = bagit.to_metadata(dri_config_two)
        self.assertEqual(actual_metadata, self.expected_metadata)

    # WHEN generate a SIP using replace_folder set as True
    # THEN closure.csv/metadata.csv have a "content" folder which has replaced the provided root folder ("not-content")

    expected_closure_b = """identifier,folder,closure_start_date,closure_period,foi_exemption_code,foi_exemption_asserted,title_public,title_alternate,closure_type\n""" + \
                       """file:/MOCKA101Y22TBAA1/MOCKA_101/content/file-c1.txt,file,,0,open,,TRUE,,open_on_transfer\n""" + \
                       """file:/MOCKA101Y22TBAA1/MOCKA_101/content/,folder,,0,open,,TRUE,,open_on_transfer\n"""

    expected_metadata_b = """identifier,file_name,folder,date_last_modified,checksum,rights_copyright,legal_status,held_by,language,TDR_consignment_ref\n""" + \
                        """file:/MOCKA101Y22TBAA1/MOCKA_101/content/file-c1.txt,file-c1.txt,file,2022-09-29T15:10:20,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,TDR-2022-AA1\n""" + \
                        """file:/MOCKA101Y22TBAA1/MOCKA_101/content/,content,folder,2022-07-18T12:45:45,,Crown Copyright,Public Record(s),"The National Archives, Kew",English,TDR-2022-AA1\n"""

    def test_bag_1_2_with_non_content_root_replaced_to_closure(self):
        bagit = make_bagit(csv_string_v_1_2_not_content, replace_folder=True)
        dri_config_two = dri_config_dict("TDR-2022-AA1", bagit.consignment_series, bagit.root_folder)
        actual_closure = bagit.to_closure(dri_config_two)
        self.assertEqual(actual_closure, self.expected_closure_b)

    def test_bag_1_2_with_non_content_root_replaced_to_metadata(self):
        bagit = make_bagit(csv_string_v_1_2_not_content, replace_folder=True)
        dri_config_two = dri_config_dict("TDR-2022-AA1", bagit.consignment_series, bagit.root_folder)
        actual_metadata = bagit.to_metadata(dri_config_two)
        self.assertEqual(actual_metadata, self.expected_metadata_b)


if __name__ == '__main__':
    unittest.main()
