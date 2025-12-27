# STACK Plugin Setup Guide

STACK (System for Teaching and Assessment using a Computer algebra Kernel) is a Moodle question type that uses Maxima for computer-aided assessment in mathematics and STEM subjects.

## Prerequisites

Before installing STACK, ensure:
- Moodle is running and accessible
- Maxima container is healthy: `docker compose ps maxima`
- You have admin access to Moodle

## Installation

### Step 1: Download STACK Plugin

1. Visit the [STACK releases page](https://github.com/maths/moodle-qtype_stack/releases)
2. Download the latest stable release ZIP file
3. Also download the [STACK behaviour plugin](https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate)

Or download via command line:

```bash
# Download STACK question type
wget https://github.com/maths/moodle-qtype_stack/archive/refs/tags/v4.6.0.zip -O qtype_stack.zip

# Download STACK behaviour
wget https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate/archive/refs/tags/v1.8.zip -O qbehaviour.zip
```

### Step 2: Install Plugins in Moodle

1. Log into Moodle as administrator
2. Go to **Site administration** → **Plugins** → **Install plugins**
3. Upload `qtype_stack.zip`
4. Follow the installation wizard
5. Repeat for `qbehaviour.zip`

Or install via command line:

```bash
# Copy plugins to Moodle container
docker compose cp qtype_stack.zip moodle:/tmp/
docker compose cp qbehaviour.zip moodle:/tmp/

# Unzip in container
docker compose exec moodle unzip /tmp/qtype_stack.zip -d /bitnami/moodle/question/type/
docker compose exec moodle mv /bitnami/moodle/question/type/moodle-qtype_stack-* /bitnami/moodle/question/type/stack

docker compose exec moodle unzip /tmp/qbehaviour.zip -d /bitnami/moodle/question/behaviour/
docker compose exec moodle mv /bitnami/moodle/question/behaviour/moodle-qbehaviour_* /bitnami/moodle/question/behaviour/dfexplicitvaildate

# Trigger Moodle upgrade
docker compose exec moodle php /bitnami/moodle/admin/cli/upgrade.php --non-interactive
```

### Step 3: Configure Maxima Connection

1. Go to **Site administration** → **Plugins** → **Question types** → **STACK**
2. Configure the following settings:

| Setting | Value |
|---------|-------|
| Platform type | Server |
| Server URL | `http://maxima:8080/` |
| Server API password | (leave empty for default) |
| CAS connection timeout | 30 |
| CAS result caching | Standard |

3. Click **Save changes**

### Step 4: Test Maxima Connection

1. On the STACK settings page, click **Health check**
2. Verify all tests pass:
   - CAS connection: ✓
   - CAS working: ✓
   - Plots working: ✓
   - LaTeX working: ✓

If tests fail, see [Troubleshooting](#troubleshooting) below.

## Creating STACK Questions

### Basic Question Structure

A STACK question consists of:
- **Question variables**: Maxima code to generate random values
- **Question text**: The question shown to students (with placeholders)
- **Input fields**: Where students enter answers
- **Potential Response Trees (PRTs)**: Logic to evaluate answers

### Example: Derivative Question

**Question Variables:**
```maxima
/* Generate random polynomial */
a: rand(5)+1;
b: rand(5)+1;
p: a*x^2 + b*x;

/* Calculate correct answer */
dp: diff(p, x);
```

**Question Text:**
```html
<p>Find the derivative of \({@p@}\) with respect to \(x\).</p>
<p>[[input:ans1]] [[validation:ans1]]</p>
<div>[[feedback:prt1]]</div>
```

**Input: ans1**
- Type: Algebraic input
- Model answer: `{#dp#}`
- Forbidden words: `diff, derivative`

**PRT: prt1**
- Node 1: Compare `ans1` with `dp` using `AlgEquiv`
  - True: Score 1, feedback "Correct!"
  - False: Score 0, feedback "Try again. Remember the power rule."

### Example: Integration Question

**Question Variables:**
```maxima
/* Random integrand */
n: rand(4)+2;
f: x^n;

/* Correct answer (indefinite integral) */
F: integrate(f, x);
```

**Question Text:**
```html
<p>Evaluate the indefinite integral:</p>
<p>\[\int {@f@} \, dx\]</p>
<p>[[input:ans1]] [[validation:ans1]]</p>
<div>[[feedback:prt1]]</div>
```

**Input: ans1**
- Type: Algebraic input
- Model answer: `{#F#}`
- Require constant of integration

### Common Input Types

| Type | Use Case |
|------|----------|
| Algebraic | Mathematical expressions |
| Numerical | Decimal numbers |
| Matrix | Matrix answers |
| True/False | Yes/no questions |
| Dropdown | Multiple choice |
| Radio | Single selection |
| Checkbox | Multiple selection |
| Textarea | Text input |
| String | Exact text match |

### Common Answer Tests

| Test | Description |
|------|-------------|
| `AlgEquiv` | Algebraic equivalence |
| `CasEqual` | Exact CAS equality |
| `NumAbsolute` | Numerical (absolute tolerance) |
| `NumRelative` | Numerical (relative tolerance) |
| `Diff` | Check if answer is derivative |
| `Int` | Check if answer is integral |
| `FacForm` | Factored form |
| `PartFrac` | Partial fraction form |

## Importing Question Banks

### From STACK Sample Questions

1. Download [STACK sample questions](https://github.com/maths/moodle-qtype_stack/tree/main/samplequestions)
2. In Moodle, go to **Question bank** → **Import**
3. Select format: **Moodle XML format**
4. Upload the XML file
5. Choose destination category
6. Click **Import**

### From OpenStax or Other Sources

1. Find STACK-compatible question banks
2. Export in Moodle XML format
3. Import as described above

### Sample Question XML

Save this as `sample_derivative.xml` and import:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<quiz>
  <question type="stack">
    <name>
      <text>Basic Derivative</text>
    </name>
    <questiontext format="html">
      <text><![CDATA[<p>Find the derivative of \({@p@}\) with respect to \(x\).</p>
<p>[[input:ans1]] [[validation:ans1]]</p>
<div>[[feedback:prt1]]</div>]]></text>
    </questiontext>
    <questionvariables>
      <text>a: rand(5)+1;
b: rand(5)+1;
p: a*x^2 + b*x;
dp: diff(p, x);</text>
    </questionvariables>
    <questionnote>
      <text>{@p@}, {@dp@}</text>
    </questionnote>
    <input>
      <name>ans1</name>
      <type>algebraic</type>
      <tans>dp</tans>
      <boxsize>15</boxsize>
      <strictsyntax>1</strictsyntax>
      <insertstars>0</insertstars>
      <syntaxhint></syntaxhint>
      <syntaxattribute>0</syntaxattribute>
      <forbidwords>diff,derivative</forbidwords>
      <allowwords></allowwords>
      <forbidfloat>1</forbidfloat>
      <requirelowestterms>0</requirelowestterms>
      <checkanswertype>0</checkanswertype>
      <mustverify>1</mustverify>
      <showvalidation>1</showvalidation>
      <options></options>
    </input>
    <prt>
      <name>prt1</name>
      <value>1.0000000</value>
      <autosimplify>1</autosimplify>
      <feedbackstyle>1</feedbackstyle>
      <feedbackvariables>
        <text></text>
      </feedbackvariables>
      <node>
        <name>0</name>
        <answertest>AlgEquiv</answertest>
        <sans>ans1</sans>
        <tans>dp</tans>
        <testoptions></testoptions>
        <quiet>0</quiet>
        <truescoremode>=</truescoremode>
        <truescore>1.0000000</truescore>
        <truepenalty></truepenalty>
        <truenextnode>-1</truenextnode>
        <trueanswernote>prt1-1-T</trueanswernote>
        <truefeedback format="html">
          <text>Correct! The derivative is \({@dp@}\).</text>
        </truefeedback>
        <falsescoremode>=</falsescoremode>
        <falsescore>0.0000000</falsescore>
        <falsepenalty></falsepenalty>
        <falsenextnode>-1</falsenextnode>
        <falseanswernote>prt1-1-F</falseanswernote>
        <falsefeedback format="html">
          <text>Incorrect. Remember the power rule: \(\frac{d}{dx}x^n = nx^{n-1}\).</text>
        </falsefeedback>
      </node>
    </prt>
    <deployedseed>12345</deployedseed>
  </question>
</quiz>
```

## Troubleshooting

### Maxima Connection Failed

1. Check Maxima container is running:
   ```bash
   docker compose ps maxima
   docker compose logs maxima
   ```

2. Test Maxima directly:
   ```bash
   curl http://localhost:8765/health
   ```

3. Restart Maxima:
   ```bash
   docker compose restart maxima
   ```

### Timeout Errors

Increase timeout in STACK settings:
- CAS connection timeout: 60 (seconds)
- CAS debugging: Enable temporarily to see errors

### Plot Images Not Displaying

1. Check Maxima can generate plots:
   ```bash
   docker compose exec maxima maxima --batch-string="plot2d(sin(x), [x,-3.14,3.14])$"
   ```

2. Verify gnuplot is installed in container

### Syntax Errors in Questions

1. Enable CAS debugging in STACK settings
2. Test Maxima code directly:
   ```bash
   docker compose exec maxima maxima
   ```
   Then enter your code to test

### Memory Issues

If Maxima runs out of memory:
1. Increase container memory limit in `docker-compose.yml`
2. Reduce pool size if needed
3. Simplify complex calculations

## Best Practices

### Question Design

1. **Use randomization**: Generate random values to prevent cheating
2. **Provide feedback**: Explain common mistakes
3. **Test edge cases**: Check boundary conditions
4. **Use question notes**: Document what each variant tests

### Performance

1. **Cache CAS results**: Enable in STACK settings
2. **Simplify expressions**: Use `ratsimp()`, `expand()` appropriately
3. **Avoid complex plots**: They increase load time

### Assessment

1. **Partial credit**: Use multi-node PRTs
2. **Multiple attempts**: Allow retry with new random values
3. **Question banks**: Organize by topic/difficulty

## Additional Resources

- [STACK Documentation](https://stack-assessment.org/)
- [Maxima Manual](https://maxima.sourceforge.io/docs/manual/)
- [STACK Community Forums](https://stack-assessment.org/community/)
- [Sample Questions Repository](https://github.com/maths/moodle-qtype_stack/tree/main/samplequestions)
