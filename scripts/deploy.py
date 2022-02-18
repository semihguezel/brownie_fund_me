from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIROMENTS,
)


def deploy_fund_me():
    account = get_account()
    # From API key taken from etherscan we can publish our smart contract on ether scan. For doing this set "publish_source =True"
    # We need price feed adress to our FundMe contract

    # if we are on a persistent network like rinkeby, use the associated address
    # otherwise, deploy mocks

    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        price_feed_adress = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_adress = MockV3Aggregator[-1].address

    fund_me = FundMe.deploy(
        price_feed_adress,
        {"from": account},
        publish_source=config["networks"][network.show_active()]["verify"],
    )
    print(f"Contract deployed to {fund_me.address}")

    return fund_me


def main():
    deploy_fund_me()
