# 04: What privacy law and consent require for collecting contributor data

Researched: 23 October 2026. Scope: UK GDPR and EU GDPR, UK and EU users, Fluidity as a UK-based developer collecting opted-in users' recordings, transcripts and corrections to train one shared speech model.

This is research from regulator guidance, court rulings, legislation and company policies. It is not legal advice. Section 8 lists the points a data protection lawyer should sign off before launch.

Terms used below, defined once:

- **Controller**: the organisation that decides why and how personal data is used. Fluidity is the controller of everything contributors upload.
- **Lawful basis**: one of the six legal grounds in GDPR Article 6 that every use of personal data needs (consent, contract, legitimate interests, and so on).
- **Special category data**: the extra-protected types in GDPR Article 9 (health, sex life, religion, politics, ethnicity, and biometric data used to identify someone). Using it needs a lawful basis *and* one of the Article 9 exceptions.
- **PECR / ePrivacy**: the UK Privacy and Electronic Communications Regulations and the EU ePrivacy Directive. Their "cookie rule" covers any software reading information stored on a user's device, apps included.
- **DPIA**: data protection impact assessment, a written risk assessment GDPR requires before high-risk processing.

## Short answer

1. **Use explicit, opt-in consent.** Three separate rules each point there:
   - uploading recordings stored on the Mac for training is outside the "strictly necessary" exception to the device-access rule;
   - free-form dictation will contain health and other special category content;
   - an on-by-default setting can never count as consent in the UK or EU.

   Legitimate interests with an opt-out (what Wispr Flow's default setting implies) does not work for UK and EU users.
2. **Voice in Fluidity's use is not "biometric" special category data**, as long as Fluidity never uses voices to identify or verify who is speaking. The *content* of dictations is the bigger problem: one sensitive item in a bundle collected together makes the whole bundle special category.
3. **A discount or free app for contributors is allowed in principle.** Conditions:
   - the incentive must not be big enough to make refusing feel like a penalty;
   - people must be able to stop contributing at any time, as easily as they started;
   - the only thing they lose on stopping is the incentive itself.

   UK regulator (ICO) guidance on "consent or pay", where users choose between consenting and paying, gives the test for whether the price gap is fair.
4. **Deletion:** when a contributor withdraws or asks for deletion, delete their raw recordings, transcripts and corrections, and never use them in future training. A model already trained on them does not have to be deleted, *unless the model itself still contains their personal data* (for example, it can reproduce their dictated text). Whether it does is something Fluidity has to test and document.
5. **Third-party data** (names, email contents, screen text inside dictations) is the hardest part. The contributor cannot consent for other people. Mitigate by:
   - redacting names and other identifiers on the device before upload;
   - letting the contributor review each item before it is sent;
   - not uploading screen text at all;
   - publishing a notice and writing a DPIA.
6. **The EU AI Act adds almost nothing** for a speech-to-text-only model. The European Commission's own guidelines say a model trained only to transcribe speech is not a "general-purpose AI model". GDPR still applies in full.

## 1. Lawful basis and consent

### 1.1 Three separate rules apply at once

**Device-access rule (PECR in the UK, ePrivacy Article 5(3) in the EU).**

- Reading information already stored on a user's device needs the user's prior consent. There are two exceptions: carrying a communication, and what is "strictly necessary" for the service the user asked for. ([EDPB voice assistant guidelines 02/2021, paras 28–29](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- The ICO says these rules "apply to any use of these technologies, including in web browsers, mobile apps and connected devices". ([ICO, what are storage and access technologies](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-storage-and-access-technologies/))
- Fluidity transcribes on the device, so training uploads mean reading recordings and transcripts off the Mac for a purpose the user did not need for dictation.
- The UK's statistics exception covers only "statistical information about visitors… with a view to improving it", for that "sole purpose", and the ICO says it "is not for identifying, tracking or monitoring people". ([ICO, what are the exceptions](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-exceptions/))
- Uploading recordings for training is very unlikely to fit that exception. That is my reading; the ICO page does not mention model training.

**GDPR Article 6 lawful basis.**

- The European Data Protection Board (EDPB) says improving a voice service is "not… (strictly) necessary for the performance of a contract". ([EDPB 02/2021, para 80](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- Where the device-access rule already requires consent, the EDPB says GDPR consent "will also, in principle, be the appropriate legal basis". Relying on legitimate interests "could… risk undermining" the device-access protection. ([EDPB 02/2021, para 87](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))

**GDPR Article 9, where special category data is involved.** See 1.2 and 1.3.

### 1.2 Is voice "biometric" special category data here?

**Not in Fluidity's planned use.**

- GDPR defines biometric data as data from "specific technical processing… which allow or confirm the unique identification" of a person. ([UK GDPR Article 4](https://www.legislation.gov.uk/eur/2016/679/article/4); quoted in [EDPB 02/2021, footnote 14](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- Article 9 covers biometric data only "for the purpose of uniquely identifying a natural person". ([UK GDPR Article 9](https://www.legislation.gov.uk/eur/2016/679/article/9))
- The ICO names "a person's voice" as a biometric characteristic, but says it "only becomes [special category] if you use it to uniquely identify someone. Your purpose… is therefore important." ([ICO biometric guidance, key concepts](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/key-data-protection-concepts/))
- The EDPB says "voice data is inherently biometric personal data". Article 9 applies when voice is processed to identify someone, or when it "is inherently or determined to be special category personal data". ([EDPB 02/2021, para 31](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- If Fluidity ever adds speaker identification, voiceprints or "is this the account owner" checks, that use needs explicit consent. The EDPB says explicit consent is the only Article 9 exception that "seems" to fit. ([EDPB 02/2021, paras 81–82, 128](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- The ICO also warns that biometric data used for other purposes "may still be considered another type of special category information", for example if it is used to infer ethnicity or health. ([ICO, key concepts](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/key-data-protection-concepts/))

### 1.3 Dictation content will contain special category data

This is the stronger reason Article 9 applies.

- **Mixed bundles count.** The EU Court of Justice (CJEU) held that where data "containing both sensitive data and non-sensitive data is… collected en bloc without it being possible to separate the data items… at the time of collection", processing the set is prohibited "if it contains at least one sensitive data item and none of the derogations in Article 9(2)… applies". (Case C-252/21 *Meta v Bundeskartellamt*, para 89, as quoted by the EDPB in [Opinion 28/2024, para 17](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))
- **Other people's data counts too.** The same court said a national court must check whether data reveals sensitive information "irrespective of whether that information concerns a user… or any other natural person". ([CJEU press release 113/23](https://curia.europa.eu/jcms/upload/docs/application/pdf/2023-07/cp230113en.pdf))
- **Likely is enough.** In *Lindenapotheke* (C-21/23, 4 October 2024), order details for non-prescription medicines were held to be health data. It was "immaterial" that the link was only probable, and this applied whether the data concerned "the customer or any other person". ([CJEU press release 159/24](https://curia.europa.eu/site/upload/docs/application/pdf/2024-10/cp240159en.pdf))
- **The ICO's test is narrower.** Its guidance focuses on whether you *intend* to infer sensitive details. ([ICO, what is special category data](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-is-special-category-data/))
- **For EU users, assume the CJEU test.** People dictate emails about doctors' appointments, therapy and relationships, so a contributor's uploads will hold special category data. For UK users, the ICO's narrower reading may apply, but a lawyer should confirm before relying on it.

Which Article 9 exceptions are realistic:

- **Explicit consent** (Article 9(2)(a)) is the only realistic one for a contributor's own data. ([UK GDPR Article 9](https://www.legislation.gov.uk/eur/2016/679/article/9))
- **The UK research exception** (DPA 2018 Schedule 1 paragraph 4) requires the processing to be "in the public interest". ([legislation.gov.uk](https://www.legislation.gov.uk/ukpga/2018/12/schedule/1/paragraph/4)) Training a commercial app's model is unlikely to meet that. A lawyer should confirm.
- **The proposed EU exception for "incidental and residual" sensitive data in AI training** (the Digital Omnibus proposal, new Article 9(2)(k)) is not law. The EDPB and the European Data Protection Supervisor (EDPS) say it "should not be understood as covering the processing of special categories of personal data collected through prompts during the deployment". ([EDPB-EDPS Joint Opinion 2/2026, paras 46–49](https://www.edpb.europa.eu/system/files/documents/2026-02/edpb_edps_jointopinion_202602_digitalomnibus_en.pdf)) User dictations are that kind of data.

### 1.4 Consent vs legitimate interests

- **Legitimate interests is a valid basis for AI training in general.** The EDPB sets a three-step test: a legitimate interest, necessity, and a balancing test that weighs people's "reasonable expectations". ([EDPB Opinion 28/2024, executive summary and paras 92–95](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))
- **For Fluidity it fails on two counts:**
  - it does not satisfy the device-access rule (1.1);
  - it is not an Article 9 exception (1.3).
- **Where legitimate interests might still matter: third parties** mentioned inside dictations, since they cannot consent (section 3).
- **UK "recognised legitimate interests" do not help.** This new basis, Article 6(1)(ea) from the Data (Use and Access) Act 2025, covers only the purposes listed in Annex 1. ([UK GDPR Article 6](https://www.legislation.gov.uk/eur/2016/679/article/6)) The ICO's summary of the new examples (direct marketing, sharing within a group, network security) does not include model training. ([ICO DUAA summary](https://ico.org.uk/about-the-ico/what-we-do/legislation-we-cover/data-use-and-access-act-2025/the-data-use-and-access-act-2025-duaa-summary-of-the-changes/data-protection/))

### 1.5 Opt-in vs on by default

- **On by default is not consent.** The ICO says: "there is no such thing as 'opt-out consent'". You "may not rely on silence, inactivity, default settings, pre-ticked boxes or your general terms and conditions". ([ICO, what is valid consent](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/consent/what-is-valid-consent/))
- **The EDPB agrees.** "The use of pre-ticked opt-in boxes is invalid", and GDPR does not allow "opt-out constructions". ([EDPB consent guidelines 05/2020, paras 79, 81](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- **The contributor setting must start off.** The user must take an action to turn it on.

### 1.6 What the consent request must contain

**Required content:**

- The controller's identity, each purpose, what data is collected, and the right to withdraw. ([EDPB 05/2020, para 64](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- Name any other controllers who rely on the consent. ([ICO, valid consent](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/consent/what-is-valid-consent/))
- Separate consents for separate purposes, "wherever appropriate". ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/consent/what-is-valid-consent/); [EDPB 05/2020, section 3.1.3](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- If consent sits inside a document covering other matters, it must be "clearly distinguishable" from them. ([UK GDPR Article 7(2)](https://www.legislation.gov.uk/eur/2016/679/article/7))

**For explicit consent:**

- It needs an express statement. A Yes/No screen is fine if the text says "I, hereby, consent to the processing of my data", but not "It is clear to me that my data will be processed". ([EDPB 05/2020, paras 93, 96](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- Fluidity must be able to prove consent was given. ([UK GDPR Article 7(1)](https://www.legislation.gov.uk/eur/2016/679/article/7))

**Withdrawal:**

- Withdrawing must be "as easy… as to give consent". ([UK GDPR Article 7(3)](https://www.legislation.gov.uk/eur/2016/679/article/7))
- It must happen through the same interface, "free of charge or without lowering service levels". ([EDPB 05/2020, paras 113–114](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))

**Retention periods** must be stated to users for each purpose. ([EDPB 02/2021, paras 95–97](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))

**Suggested shape**, my draft, to be checked by a lawyer:

- A separate screen, never inside the terms of service, with two unticked choices:
  - [ ] *I consent to Fluidity Ltd storing the recordings, transcripts and corrections I choose to send, and using them to train the shared speech model that ships to all Fluidity users. These may include sensitive details I say aloud, such as health information.*
  - [ ] (optional, separate) *I consent to a Fluidity staff member listening to some of my recordings to check transcription accuracy.*
- Underneath, in plain text:
  - what is collected (audio, transcript, your edits, app name, and whether screen text is collected);
  - how long it is kept;
  - that you can stop at any time from the same settings screen;
  - what stopping does (no new uploads, past uploads deleted within N days, models already released are not recalled unless they contain your data, see section 2);
  - what you get, and lose on stopping (the discount);
  - a link to the privacy notice.

### 1.7 Free or discounted app in exchange for contributions

**What the rules say:**

- **Bundling test.** GDPR asks whether a service is "conditional on consent to the processing of personal data that is not necessary for the performance of that contract". ([UK GDPR Article 7(4)](https://www.legislation.gov.uk/eur/2016/679/article/7)) Fluidity works fully on device, so contributing is not necessary for the service. Any link between price and contributing therefore needs care.
- **Incentives are allowed.** "The GDPR does not preclude all incentives", but the controller must show consent was still free. ([EDPB 05/2020, para 48](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- **Losing the incentive is not a penalty.** EDPB Example 9: a shopper who withdraws consent goes back to non-personalised discounts, and "This does not amount to detriment as only the permissible incentive was lost". ([EDPB 05/2020, para 50](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- **Degrading the app is a penalty.** EDPB Example 8: an app that "now only works to a limited extent" after withdrawal never had valid consent, and the data must be deleted. ([para 49](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- **ICO view on incentives.** "It may still be possible to incentivise consent to some extent", but "you must be careful not to cross the line and unfairly penalise those who refuse consent". Its example is a loyalty scheme giving vouchers for marketing consent. ([ICO, valid consent](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/consent/what-is-valid-consent/))
- **The CJEU's "pay or consent" ruling.** Users who refuse should be offered, "if necessary for an appropriate fee, an equivalent alternative not accompanied by such data processing operations". (*Meta v Bundeskartellamt*, C-252/21, para 150, quoted in [EDPB Opinion 08/2024, para 53](https://www.edpb.europa.eu/system/files/2024-04/edpb_opinion_202408_consentorpay_en.pdf)) The EDPB's opinion on that ruling is limited to "large online platforms" and behavioural advertising, so it does not bind a small app directly. ([Opinion 08/2024, summary](https://www.edpb.europa.eu/system/files/2024-04/edpb_opinion_202408_consentorpay_en.pdf))
- **ICO "consent or pay" guidance.**
  - An appropriate fee is "an amount at which people can freely give their consent".
  - The controller must be able to show its fee is appropriate.
  - Watch for groups who would be "priced out".
  - The guidance is written around personalised advertising, but its tests are the closest UK benchmark for a "contributor discount".

  ([ICO consent or pay, appropriate fee](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/online-tracking/consent-or-pay/appropriate-fee/))

**What this means for Fluidity:**

- The paid, non-contributing version must be the same app.
- The price gap should be modest and justified in writing.
- Stopping contributing ends the discount from the next billing period, and nothing else.
- Never charge back past discounts or lock features.
- "Free only if you contribute" is the riskiest version. A lawyer should look at it, especially since it shades into the EU consumer-law treatment of personal data supplied instead of a price (Digital Content Directive 2019/770). I could not fetch that directive's text; see section 9.

## 2. Retention, deletion and the trained model

**Retention:**

- Keep each data type only as long as its purpose needs.
- Set a maximum per data set and purpose.
- "Retaining personal data indefinitely goes against the storage limitation principle", and offering a delete button does not replace a retention policy.

([EDPB 02/2021, paras 95–98](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))

**Withdrawal or deletion request (raw data):**

- After withdrawal the controller "must stop the processing", and if no other basis exists, the data "should be deleted". ([EDPB 05/2020, paras 117, 119](https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf))
- Delete "the initial voice recording as well as any related transcription". ([EDPB 02/2021, para 162](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- Deletion must reach the device "and… all remote storage systems". ([para 99](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- "Providers should ensure that all users' data can be erased at the user's request". ([para 147](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- Anonymising voice is "specially challenging", so deletion, not anonymisation, should be the default. ([paras 105, 160](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))

**Models already trained on the data. Regulators answer "not automatically, but test it":**

- **EDPB, on withdrawn consent.** The data "can no longer be used for further training of the model. Nevertheless, the model previously trained using this data does not have to be deleted." The EDPB adds that models can leak training data through reconstruction and membership inference attacks (ways of extracting training data, or detecting who was in it, by querying the model). So controllers should "use models which do not restrict their ability to stop processing" and reduce re-identification risk. ([EDPB 02/2021, paras 101–103](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- **EDPB, on when a model counts as anonymous.** A model is anonymous only if both of these are "insignificant": extracting training data from it directly, and getting personal data out of it through queries. ([Opinion 28/2024, summary and para 31](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))
- **EDPB, on extra safeguards.** It lists optional extras: an unconditional opt-out, erasure even where Article 17 would not require it, and accepting claims that the model "memorised" someone's data so the controller can "assess relevant unlearning techniques". ([Opinion 28/2024, para 102](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))
- **ICO, on models.** Erasure "does not entail erasing all ML models based on this data, unless the models themselves contain that data". Where they do, fixing it "may not be possible without re-training the model… or deleting the model altogether". ([ICO AI guidance, individual rights](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/artificial-intelligence/guidance-on-ai-and-data-protection/how-do-we-ensure-individual-rights-in-our-ai-systems/))
- **ICO, on unlearning and filters.** In its 2024 generative AI response, the ICO says organisations need ways to handle rights requests for training data "and, if a model contains personal data, the trained model itself". Respondents called machine unlearning (techniques to remove one person's influence from a trained model without full retraining) mostly theoretical. Output filters "may not be sufficient, as they do not actually remove the data from the model". ([ICO, engineering individual rights into generative AI](https://ico.org.uk/about-the-ico/what-we-do/our-work-on-artificial-intelligence/response-to-the-consultation-series-on-generative-ai/engineering-individual-rights-into-generative-ai-models/))
- **If training was unlawful,** a regulator can order deletion of the data set "and/or the AI model itself", taking retraining into account. ([Opinion 28/2024, para 114](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))

**What this means for Fluidity.** The shared model ships to every user's Mac, so a model that can reproduce a contributor's dictated words would be handing that person's data to everyone. In practice:

- Test released models for memorisation, for example by prompting with rare names or phrases from the training set, and keep the results.
- Version every training set, so a withdrawn contributor's data is left out of the next training run.
- State in the consent text that released model versions are not recalled.

## 3. Third-party personal data inside dictations

Dictations will contain other people's names, email contents and, if collected, screen text. Fluidity becomes the controller of that data on upload.

**Their consent is impossible.** The contributor can only consent for themselves. Third parties need their own Article 6 basis, realistically legitimate interests with the three-step test. ([EDPB Opinion 28/2024](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf))

**Their sensitive data has no clean exception.** A contributor dictating "my sister's chemo starts Monday" uploads a third party's health data. The CJEU counts that regardless of whose it is (1.3), and the contributor's explicit consent does not cover the sister. This is the largest legal gap I found. A lawyer is needed.

**Mitigations regulators name:**

- **Mask or replace names and email addresses** in training data, which is "particularly appropriate when the actual substantive content of the data is not relevant". ([Opinion 28/2024, para 101(c)](https://www.edpb.europa.eu/system/files/documents/2024-12/edpb_opinion_202428_ai-models_en.pdf)) For speech this is harder, since names are spoken in the audio. Transcript-side replacement and dropping clips that contain names are options.
- **Accidentally captured people** (bystanders, unintended recordings): check there is a basis for each purpose, "Otherwise, the accidentally collected data should be deleted". ([EDPB 02/2021, para 30](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- **Human reviewers** should "always receive the strictly necessary pseudonymised data". ([EDPB 02/2021, para 123](https://www.edpb.europa.eu/system/files/2021-07/edpb_guidelines_202102_on_vva_v2.0_adopted_en.pdf))
- **Telling third parties** (Article 14). Writing to everyone named is impractical. The ICO's "disproportionate effort" exception "should be treated as the exception, not the rule". Even when it applies, you must "still publish the privacy information" and should do a DPIA. ([ICO, right to be informed: exceptions](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/the-right-to-be-informed/are-there-any-exceptions/))
- **Not knowing who someone is does not excuse ignoring their rights.** The ICO says Article 11 (the rule for data you cannot link to a person) must not be used to undermine rights requests. ([ICO generative AI response](https://ico.org.uk/about-the-ico/what-we-do/our-work-on-artificial-intelligence/response-to-the-consultation-series-on-generative-ai/engineering-individual-rights-into-generative-ai-models/))

**Practical design implied by the above** (my inference, not a regulator's list):

- Contributors choose what to send, per dictation or per batch, with a preview.
- Fluidity removes names and other identifiers on the device before upload.
- Never upload screen text or contents from password fields.
- Allow excluding apps (mail, health, messaging).
- Contributor terms ask people not to dictate sensitive details about others. Common Voice's Spontaneous Speech terms do exactly this (section 6).

## 4. EU AI Act

- **Scope.** The Act applies to non-EU providers placing models on the EU market. Article 2(7) keeps GDPR applying unchanged. ([AI Act Article 2](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-2))
- **Training-data duties sit on general-purpose models.** These are Article 53: technical documentation, a copyright policy, and a public "sufficiently detailed summary about the content used for training". ([Article 53](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-53)) A general-purpose model is one with "significant generality" that can do "a wide range of distinct tasks". ([Article 3(63)](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-3))
- **A transcription-only model is not one.** The Commission's July 2025 guidelines give this exact example. A model trained "specifically for the task of transcribing speech to text" with 10^24 FLOP (a measure of training compute) "is not actually a general-purpose AI model" if it can only perform that narrow task. ([Commission GPAI guidelines C(2025) 5045](https://ai-act-service-desk.ec.europa.eu/sites/default/files/2025-07/guidelines_on_the_scope_of_the_obligations_for_generalpurpose_ai_models_established_by_regulation_1cx2atxgq79us4n3x8jfgyy1qlm_118340-3.pdf))
- **Features that would change this.** "Emotion recognition" and "biometric categorisation" are defined by use of biometric data. ([Article 3(39)–(40)](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-3)) Adding emotion detection from voice, or sorting speakers by traits, would pull Fluidity into the Act's stricter rules. I did not check the Annex III and Article 5 text in detail.

## 5. Other UK and EU obligations this triggers

- **DPIA.**
  - Required for "processing on a large scale of special categories of data". ([GDPR Article 35(3)(b), as quoted by the ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/))
  - The ICO's list also covers "innovative technologies… (including AI)" and data "not obtained direct from the data subject" when combined with another risk factor. ([ICO, when do we need a DPIA](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/))
  - Expect to need one before launch.
- **EU representative.** A non-EU controller covered by GDPR must appoint an EU representative. The exemption applies only where processing is "occasional" and does not include large-scale special category data. ([EDPB territorial scope guidelines 3/2018, section 4](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_3_2018_territorial_scope_after_public_consultation_en_1.pdf)) A UK developer collecting EU contributors' dictations probably needs one.
- **Children.** UK GDPR Article 8 sets 13 as the age for consenting to online services, with a new power to raise it up to 16. ([legislation.gov.uk Article 8](https://www.legislation.gov.uk/eur/2016/679/article/8)) EU states set 13–16. Common Voice requires parental consent and supervision for anyone 19 or under. ([Common Voice terms](https://github.com/mozilla/legal-docs/blob/main/en/common_voice_terms.md)) Limiting contributing to adults avoids the question.
- **UK Data (Use and Access) Act 2025:**
  - "scientific research" can now include "commercial research";
  - consent to "an area of scientific research" is allowed under conditions;
  - complaints must be acknowledged within 30 days.

  ([ICO DUAA summary](https://ico.org.uk/about-the-ico/what-we-do/legislation-we-cover/data-use-and-access-act-2025/the-data-use-and-access-act-2025-duaa-summary-of-the-changes/data-protection/))
  - Several ICO pages cited here carry the note "under review" because of this Act. Recheck them before launch.
  - The research changes do not remove the Article 9 problem (1.3).
- **Pending EU change.** The Digital Omnibus proposal would add a GDPR article on legitimate interests for AI (Article 88c) and the Article 9(2)(k) exception above. The EDPB and EDPS say Article 88c "does not bring any legal clarification" beyond Opinion 28/2024. ([Joint Opinion 2/2026, para 39](https://www.edpb.europa.eu/system/files/documents/2026-02/edpb_edps_jointopinion_202602_digitalomnibus_en.pdf)) I could not confirm its legislative status from a primary source (section 9).

## 6. How others handle it

| | Wispr Flow | Mozilla Common Voice | Apple Siri & Dictation | Otter.ai |
|---|---|---|---|---|
| What is used for training | "audio, transcript, edits" ([data controls](https://wisprflow.ai/data-controls)) | Read-aloud recordings plus optional accent, age and gender, published under the CC0 public-domain licence ([privacy notice](https://github.com/mozilla/legal-docs/blob/main/en/common_voice_privacy_notice.md)) | By default, transcripts tied to a rotating random ID, kept up to 2 years. Audio stored only if the user opts in ([Apple](https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)) | "de-identified audio recordings and… transcriptions (which may contain Personal Information)" ([privacy policy](https://otter.ai/privacy-policy)) |
| Default | Growth and Enterprise: "off by default and locked" ([privacy page](https://wisprflow.ai/privacy)). The pages do not state the Free and Pro default (see note) | Contributing is the whole point; there is no passive collection | Audio: off unless "Improve Siri and Dictation" is chosen at setup ([Apple](https://www.apple.com/legal/privacy/data/en/improve-siri-dictation/)) | No toggle described. Basis listed as "Consent or Legitimate interests" |
| Lawful basis stated | Lists contract, legitimate interests, consent and legal obligation without mapping them to uses ([privacy policy](https://wisprflow.ai/privacy-policy)) | Not stated in the notice | Not stated on these pages | As above |
| Human review | Not stated | Community validation | "Only Apple employees" hear audio. A reviewed subset may be kept beyond 2 years ([Apple](https://www.apple.com/legal/privacy/data/en/improve-siri-dictation/)) | Data labelling vendors ([privacy policy](https://otter.ai/privacy-policy)) |
| Deletion | Rights requests by email. Nothing said about models already trained ([privacy policy](https://wisprflow.ai/privacy-policy)) | When deleting a profile, users can ask to remove recordings. Mozilla "will review your request" and, if approved, "contact those who have downloaded the dataset and request they remove" them. Keeping recordings is final ([delete screen text](https://github.com/common-voice/common-voice/blob/main/web/locales/common-voice/en/pages/profile/delete.ftl)) | "Delete Siri & Dictation History" deletes on-device transcripts. Server-side data is tied to random IDs, not the account ([Apple](https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)) | General erasure right. Says it renders deleted data "irrecoverable" ([privacy policy](https://otter.ai/privacy-policy)) |
| Third-party data | Optional "Context Awareness" reads "text on the screen" ([privacy policy](https://wisprflow.ai/privacy-policy)) | Scripted sentences. Spontaneous Speech contributors "agree not to include any sensitive or personal data about yourself and others" ([terms](https://github.com/mozilla/legal-docs/blob/main/en/common_voice_terms.md)) | Reviewers "may access… names of your contacts" | Meetings capture other participants |

Notes:

- **Wispr Flow's Free and Pro default.** The ticket says training is on by default for Free and Pro. Wispr's published pages (privacy policy updated 19 August 2026, data controls updated 18 August 2026) do not state that default. The privacy policy words it as opt-in: "If you choose to share your content with us for model training". ([privacy policy](https://wisprflow.ai/privacy-policy)) The data controls page says the setting "was previously called 'Privacy Mode'". ([data controls](https://wisprflow.ai/data-controls)) I could not confirm the in-app default from a primary source.
- **Common Voice is the closest model to copy** for a consent-first, contributor-led data set. It is US-law-governed (California) and publishes everything under CC0, which Fluidity would not.
- **Apple shows the UK and EU pattern:** audio is opt-in, the prompt appears at setup, and stored data is not tied to the account.

## 7. Recommended position for Fluidity

My synthesis from the sources above:

1. Contributing is opt-in, off by default, on its own screen, with explicit consent wording that mentions sensitive content.
2. Contributors choose what to send, with a per-item preview. Names and other identifiers are removed on the device. Screen text is never uploaded.
3. Separate, optional consent for human listening.
4. Stopping is one toggle in the same settings screen. It stops uploads at once, deletes stored contributions within a stated time, and excludes them from the next training run. The only effect on the contributor is losing the discount.
5. The paid non-contributor app is identical. Write down why the discount size is fair, using the ICO consent-or-pay tests.
6. Written retention periods per data type. Version training sets. Test and record memorisation for every released model.
7. Write a DPIA, publish a training-data notice for third parties, appoint an EU representative, and limit contributing to adults.

## 8. Where a lawyer is needed

- Whether contributors' consent plus legitimate interests covers *third parties'* special category data in dictations, or whether Fluidity must filter it out before upload (section 3). This is the biggest open risk.
- Whether the ICO's intent-based special category test can be relied on for UK users, given the CJEU's wider test for EU users (1.3).
- The free or discounted tier: size of the gap, and whether "free only if you contribute" works under Article 7(4) and EU consumer law (1.7).
- Final consent wording and privacy notice.
- EU representative, and whether the DPIA must go to the ICO for prior consultation.
- Whether released models count as anonymous, and therefore whether deletion requests must reach shipped models (section 2).

## 9. What I could not establish

- **CJEU judgments read through secondary routes.** EUR-Lex and the CJEU's InfoCuria site blocked automated fetches. I read *Meta v Bundeskartellamt* (C-252/21) paras 89 and 150 through the EDPB's quotations, and *Lindenapotheke* (C-21/23) through the CJEU's own press release. I did not read *OT* (C-184/20) at all.
- **EU-only legislation text.** GDPR articles are cited from the UK GDPR on legislation.gov.uk; the EU text matches for the articles used, apart from UK-only additions such as Article 6(1)(ea). I could not check the Digital Content Directive 2019/770 text on data supplied instead of a price.
- **Digital Omnibus status.** Whether the GDPR part has been adopted as of October 2026. The EDPB-EDPS opinion confirms only the proposal's content; news sources disagree on later Council drafts.
- **Wispr Flow's Free and Pro default.** As noted above, the published pages do not state it.
- **EDPB Guidelines 2/2019 on the contract basis.** Not read directly; the EDPB's voice assistant guidelines restate its position on service improvement (para 80).
