//
//  CommonFirmwareTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 07.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
@testable import TangemSdk
import CryptoKit

/// Firmware tests snippets.
@available(iOS 16.0, *)
class CommonFirmwareTests: FWTestCase {
    /// Go to BLS lib and generate public keys for all mnemonics from BIP39
    func getAllPrivateKetsForBLS() {
        let mnemonics = [
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
            "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
            "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
            "scheme spot photo card baby mountain device kick cradle pact join borrow",
            "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
            "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
            "cat swing flag economy stadium alone churn speed unique patch report train",
            "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
            "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
            "vessel ladder alter error federal sibling chat ability sun glass valve picture",
            "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
            "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
        ]

        let addresses = mnemonics.map { str in
            try! AnyMasterKeyFactory(mnemonic: try! Mnemonic(with: str), passphrase: "TREZOR").makeMasterKey(for: .bls12381_G2_AUG).privateKey.hexString
        }

        print(addresses)
    }

    /// Generated public keys from chia-bls for all mnemonics from BIP39
    func testMnemonicsBLS() {
        let mnemonics = [
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
            "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
            "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
            "scheme spot photo card baby mountain device kick cradle pact join borrow",
            "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
            "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
            "cat swing flag economy stadium alone churn speed unique patch report train",
            "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
            "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
            "vessel ladder alter error federal sibling chat ability sun glass valve picture",
            "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
            "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
        ]

        let generatedPublicKeys = [
            "a2c975348667926acf12f3eecb005044e08a7a9b7d95f30bd281b55445107367a2e5d0558be7943c8bd13f9a1a7036fb",
            "881b618bfdfd0e30ed975242a01b59dcb630605a5fa59f67676f176a6495b2e4245cca2352d96f3b6d2102e7847bbf90",
            "a4121374ef760d9d3e6237f7d66d02926ce750644b32381bdb2ca1eb11ca6f04e0b0879f6a736efbde8d7f31e35d67f1",
            "96f291d24e5c40e71676379c9c11001334c57afb1fe84238b4dd4ac16670b0797e42c51898bee9d3a314e37a71039c70",
            "b7d4c9070e4057085dc24184766be6314a3a6ed1b31c27172d8888cbd9fba428613a0792b0c67c1cfcefe598c09ab08c",
            "971f542a3f08ccc7527a2265b455193718ded0b7235d92c110206e575fb6a456cbf7430bb28311848f3d11483b045997",
            "910b63ea4482a66bb4583d971374c23615a4af6b4224c71f2ac5ec05a1436f78a56c987ac090f99134cdc3bc8be28a93",
            "852d4fb5c04e9e818ad41b33f38771472dae9c509a59f44920435ac2d3a148efd9acee50a1d4c438e29ee4aa83a32277",
            "8171d9527eaf5984a84fd7e40ebf9b0c15270352b3ffd7cc079c07b5361ca6926bb10748c7ebf29988a388164c05b577",
            "937155d84592a90a4ece2d8bb4626b7ee5d84ffb93e8ed9acbad5b1200fc944fee38f2f34b8807eaa2abcfe204580072",
            "b1760a20cd6874d53fb8ee954b65858f847029ddb43a57365456da7b9e4912f9128d9d472059a944189b970b6a3810c1",
            "a78456920e38f9417f43ad8b03826a3f6897ae6019fe43cc0ef2c100d526b15583b05bc42a8ad63df17f89de31413f1e",
            "8d356647d909aca4b9310de96337a9a931a4bdeddf1c8828bace4b15f2f8b740d769942fcbadf9dd1dd9cd3fb4e2ca27",
            "a6d8551cfcf8aefa062c60ffa246466c158e017fba12570327f47a004d5846cf2fabc2952b8f1653f7d224efd9d9b826",
            "b716f9b7913709d319781d786d3d61f87387e646e6a8062dcf3eb0fcbc745569a6d1ced8c94339d71318ffd20d91a645",
            "b5fbb6589559306e44528371c86ea9a6eda9ce7729747e6a88447035c74bb45e9e0a56327b95e5293ecfd258465ebf0e",
            "b6ef07d20b41029a0a21e0123bf8288bb42fa386fae77aea54a0012921268424a46bbf3afaf1d5d9b96399fbdba4d968",
            "b097208a6ac74155715bdcd717e837375fbfa8e4ab245f85e84aa6c106d8b5665f616bf20a5a5b384098fd491cfd15cc",
            "a37bd2c6d7fc4ff41f04d2dfbc1f76e2ef51d61839bd7904d5970076154a348ee27e9f682ba90e8bc6f0519f02bfd3fd",
            "80c0b4881ba58847d859493565c7af148c1da9fb899ef4909e4b7aba4b5699b5b5a82020b71d4dd6fb225dbd96f74f8c",
            "8f28822312f7ff9e6fd81eaeeb1c60749abe071321e56cd52269893a03b9c2690e4410892a5464c82320239fe3a81d34",
            "8790179e6e31055fdf22bd7ab1a6b9f7bc86afbb7c36a36b9a79f94edc101d1575b29101909e927bba98f154c9d419fe",
            "ac188745db0b9442313bc027118214f007ffc06c43a2eb4020a1d47cd1422480190639e7775b133fc999e8dccd8ba26c",
            "8793a32f2bf261acabcbfc67f33c0c5278463826e677438b7801136ffd0c8aeb22626a3abb57da9d414a58bae16a2096",
        ]
        let passphrase = "TREZOR"

        let cmds = mnemonics.map {
            let mnemonic = try! Mnemonic(with: $0)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase)
            let prvKey = try! factory.makeMasterKey(for: .bls12381_G2_AUG)
            let cmd = CreateWalletTask(curve: .bls12381_G2_AUG, privateKey: prvKey)
            return (cmd, prvKey)
        }

        let tangemSdk = TangemSdk()

        tangemSdk.startSession { session, error in

            for cmd in cmds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(3*Double(cmd.0))) {
                    cmd.1.0.run(in: session) { resp in
                        switch resp {
                        case .success(let r):
                            let key = r.wallet.publicKey.hexString.lowercased()
                            //let expected = try! cmd.1.1.makePublicKey(for: .ed25519_slip0010).publicKey
                            let expected = generatedPublicKeys[cmd.0]
                            let equals = key == expected
                            // print(key)
                            print("!!! \(cmd.0) \(equals ? "✅" : "❌")")
                        case  .failure(let error):
                            print("!!! \(error.localizedDescription)")
                            print("!!! ❌❌❌")
                            break
                        }

                    }
                }

            }
        }
    }

    /// Generated public keys from WalletCore for all mnemonics from BIP39
    func testMnemonicsEd25519() {
        let mnemonics = [
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
            "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
            "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
            "scheme spot photo card baby mountain device kick cradle pact join borrow",
            "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
            "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
            "cat swing flag economy stadium alone churn speed unique patch report train",
            "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
            "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
            "vessel ladder alter error federal sibling chat ability sun glass valve picture",
            "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
            "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
        ]

        let generatedPublicKeys = [
            "0137fdfdbe9ac856469f8d83c66c57880246cd8bf7f852bf5b94336fe535c0efc8",
            "01c388082aa0af024e28d4b08e7f8d43520364205ad99f51e6b70c878f0035b535",
            "01861bbbc43e0d32a59056188a6b817312e34ab5222182e4313fe547b0bbf52765",
            "01c65d6d1bfe05ea19c8fa56a44ff3a3df3f1fbde47a97eea98f2d648acb329f0f",
            "01f3784f120d3d8fb1cd421faf57380bea6fa66133d711b351869b1dc7e529b699",
            "01848c67b03191a52b103a0116a305dc935a8b88cbace5d1ec5c62d1f0738db42b",
            "01f2fa67986f45a056833235af4a70a71f372f9970d1aa466c1765f6c913961a6a",
            "0192a6a3560a42a5cf7facf0f349a7e4956c51ae3fc9bca49fe061ff10014a9a11",
            "0151aa1dcac6324b41cb184e27589a208b7f1c941c620e1e0d10414c979989a7c2",
            "01b4a235a16bfb75e8713ae72d420cba8f5b6b48fe66da9d858968a311131f64b0",
            "015c4f844cf4722989e39d5a16507c82c7e35b9ee7ee3621789c8046f9cb031242",
            "01b26be5c118159882386e2b301486108a9d92cc7346c419f3f8e0fc74e89b0fe3",
            "01f64b4fd74478b4e71704ce152c930785e757e67837d5857ba716d9a574ca8717",
            "018d1dbcbe742b3db49533a3ee1166e9b69348fe200a2369443973b826e65b6a61",
            "0185b0862e7a0aace9300d2563ecdf66dba45d36ad621fbe6b112c7980932ad353",
            "011ec7ac91704195b164ea9d34694fdc52681e9fe5a87602ed8e74bfa29a67807b",
            "010d4ffd87e8c7c5a1929eb4ce1feac76222523e6c91ca37e465426de5b79e8d96",
            "017aafc561eb2d8a6326a4883b4722d60a8c0e5f240cc0bdf5cd5068298b59f35a",
            "01650f12dd9472b90712625c1768d58f0e2673a9c575b8ec1b9d119e2c0e4123f2",
            "0165671f076c4478747299db38b97d3039bdc45dd39e6f829e9dbb829452a5a95f",
            "015d4f074f4f067b70a7b69808277224f7f15531a5e17bc59847f24f7bd59e2904",
            "01dd277e344a6505a80ebfb366545e023cfba05bf7ee2f0d8de1240778456d5bcc",
            "010e304751311432c4ffb107cee6a4fc56fa3fbd43e7f354da5166c3915400feff",
            "01539f7909fe0243b862dd4395d2c8575bf070d22931952e94fb46d9aa557fa46a",
        ]

        let cmds = mnemonics.map {
            let mnemonic = try! Mnemonic(with: $0)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: "")
            let prvKey = try! factory.makeMasterKey(for: .ed25519)
            let cmd = CreateWalletTask(curve: .ed25519, privateKey: prvKey)
            return (cmd, prvKey)
        }

        let tangemSdk = TangemSdk()


        tangemSdk.startSession { session, error in

            for cmd in cmds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(0.5*Double(cmd.0))) {
                    cmd.1.0.run(in: session) { resp in
                        switch resp {
                        case .success(let r):
                            let key = r.wallet.publicKey.hexString.lowercased()
                            //let expected = try! cmd.1.1.makePublicKey(for: .ed25519_slip0010).publicKey
                            let expected = generatedPublicKeys[cmd.0]
                            let equals = key == expected.dropFirst(2)
                            // print(key)
                            print("!!! \(cmd.0) \(equals ? "✅" : "❌")")
                        case  .failure(let error):
                            print("!!! \(error.localizedDescription)")
                            print("!!! ❌❌❌")
                            break
                        }

                    }
                }
            }
        }
    }

    // All mnemonics from BIP39
    func testMnemonicsSecp256k1() {
        let mnemonics = [
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
            "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
            "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
            "scheme spot photo card baby mountain device kick cradle pact join borrow",
            "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
            "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
            "cat swing flag economy stadium alone churn speed unique patch report train",
            "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
            "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
            "vessel ladder alter error federal sibling chat ability sun glass valve picture",
            "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
            "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
        ]

        let pass = "TREZOR"

        let cmds = mnemonics.map {
            let mnemonic = try! Mnemonic(with: $0)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: pass)
            let prvKey = try! factory.makeMasterKey(for: .secp256k1)
            let cmd = CreateWalletTask(curve: .secp256k1, privateKey: prvKey)
            return (cmd, prvKey)
        }

        let tangemSdk = TangemSdk()

        tangemSdk.startSession { session, error in

            for cmd in cmds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(0.5*Double(cmd.0))) {
                    cmd.1.0.run(in: session) { resp in
                        switch resp {
                        case .success(let r):
                            let key = r.wallet.publicKey.hexString
                            let expected = try! cmd.1.1.makePublicKey(for: .secp256k1).publicKey.hexString
                            self.printEquals(expected, key)
                        case .failure(let error):
                            print(error)
                            break
                        }

                    }
                }
            }

            withExtendedLifetime(tangemSdk, {})
        }
    }

    // All mnemonics from BIP39
    func testMnemonicsSecp256r1() {
        let mnemonics = [
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
            "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
            "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
            "scheme spot photo card baby mountain device kick cradle pact join borrow",
            "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
            "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
            "cat swing flag economy stadium alone churn speed unique patch report train",
            "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
            "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
            "vessel ladder alter error federal sibling chat ability sun glass valve picture",
            "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
            "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
        ]

        let pass = "TREZOR"

        let cmds = mnemonics.map {
            let mnemonic = try! Mnemonic(with: $0)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: pass)
            let prvKey = try! factory.makeMasterKey(for: .secp256r1)
            let cmd = CreateWalletTask(curve: .secp256r1, privateKey: prvKey)
            return (cmd, prvKey)
        }

        let tangemSdk = TangemSdk()

        tangemSdk.startSession { session, error in

            for cmd in cmds.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(0.5*Double(cmd.0))) {
                    cmd.1.0.run(in: session) { resp in
                        switch resp {
                        case .success(let r):
                            let key = r.wallet.publicKey.hexString
                            let expected = (try! P256.Signing.PrivateKey(rawRepresentation: cmd.1.1.privateKey)).publicKey.compressedRepresentation.hexString.uppercased()
                            self.printEquals(expected, key)
                        case .failure(let error):
                            print(error)
                            break
                        }

                    }
                }
            }

            withExtendedLifetime(tangemSdk, {})
        }
    }
}

