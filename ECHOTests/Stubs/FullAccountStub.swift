//
//  FullAccountStub.swift
//  ECHOTests
//
//  Created by Fedorenko Nikita on 22.08.2018.
//  Copyright © 2018 PixelPlex. All rights reserved.
//

import Foundation

struct FullAccountStub {
    
    let initialJson = """
                    {
                      "withdraws": [],
                      "limit_orders": [],
                      "proposals": [],
                      "vesting_balances": [],
                      "votes": [],
                      "referrer_name": "faucet",
                      "lifetime_referrer_name": "faucet",
                      "registrar_name": "faucet",
                      "call_orders": [],
                      "statistics": {
                        "id": "2.6.23240",
                        "is_voting": false,
                        "pending_fees": 0,
                        "owner": "1.2.23240",
                        "removed_ops": 0,
                        "most_recent_op": "2.9.75402266",
                        "pending_vested_fees": 0,
                        "total_ops": 39,
                        "total_core_in_orders": 0,
                        "core_in_balance": "10035186229",
                        "lifetime_fees_paid": 13771,
                        "name": "nikitatest1",
                        "has_cashback_vb": false
                      },
                      "balances": [
                        {
                          "id": "2.5.24807",
                          "owner": "1.2.23240",
                          "maintenance_flag": false,
                          "balance": 10035186229,
                          "asset_type": "1.3.0"
                        }
                      ],
                      "settle_orders": [],
                      "account": {
                        "active": {
                          "weight_threshold": 1,
                          "account_auths": [],
                          "key_auths": [
                            [
                              "TEST7okvxowDi4pdvJt1t8ksPZFwaemAcFtP8K7cDPcsVnjDbHa1FW",
                              1
                            ]
                          ],
                          "address_auths": []
                        },
                        "lifetime_referrer": "1.2.17",
                        "options": {
                          "num_committee": 0,
                          "votes": [],
                          "extensions": [],
                          "voting_account": "1.2.5",
                          "memo_key": "TEST7okvxowDi4pdvJt1t8ksPZFwaemAcFtP8K7cDPcsVnjDbHa1FW",
                          "num_witness": 0
                        },
                        "owner": {
                          "weight_threshold": 1,
                          "account_auths": [],
                          "key_auths": [
                            [
                              "TEST7okvxowDi4pdvJt1t8ksPZFwaemAcFtP8K7cDPcsVnjDbHa1FW",
                              1
                            ]
                          ],
                          "address_auths": []
                        },
                        "referrer_rewards_percentage": 5000,
                        "network_fee_percentage": 2000,
                        "name": "nikitatest1",
                        "whitelisted_accounts": [],
                        "membership_expiration_date": "1970-01-01T00:00:00",
                        "id": "1.2.23240",
                        "registrar": "1.2.17",
                        "referrer": "1.2.17",
                        "whitelisting_accounts": [],
                        "blacklisted_accounts": [],
                        "statistics": "2.6.23240",
                        "owner_special_authority": [
                          0,
                          {}
                        ],
                        "blacklisting_accounts": [],
                        "top_n_control_flags": 0,
                        "active_special_authority": [
                          0,
                          {}
                        ],
                        "lifetime_referrer_fee_percentage": 3000
                      },
                      "assets": []
                    }
                """
}
