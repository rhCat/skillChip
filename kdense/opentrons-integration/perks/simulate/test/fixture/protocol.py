from opentrons import protocol_api

metadata = {
    'protocolName': 'Fixture Protocol',
    'author': 'skilltest',
    'description': 'Tiny protocol for the simulate perk test',
    'apiLevel': '2.19'
}

requirements = {
    'robotType': 'Flex',
    'apiLevel': '2.19'
}


def run(protocol: protocol_api.ProtocolContext):
    tips = protocol.load_labware('opentrons_flex_96_tiprack_200ul', 'D1')
    plate = protocol.load_labware('nest_96_wellplate_200ul_flat', 'D2')
    pipette = protocol.load_instrument('p300_single_flex', 'left', tip_racks=[tips])
    pipette.transfer(50, plate['A1'], plate['B1'], new_tip='always')
