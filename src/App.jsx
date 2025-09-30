import { useState, useMemo } from "react";

/** 1) SET YOUR APPS SCRIPT WEBHOOK URL HERE */
// Use the Web App URL that returns {"ok":true,"hello":"ClickApp"} when opened
const ENDPOINT_URL = "https://script.googleusercontent.com/macros/echo?user_content_key=AehSKLj49Ph0Bvg4W8pSdXOn2n4NALlZewqwq05oGjoeyipd23VNioo4mY52EvAhzBKhPjZsfRdQwn8Db2Q4PgbL8HN4j_-32grSSG0dS2az-vdixavrWcj92HF8kxsMqUPdRrns5TfVDhwVBY9SM-nRFddX4cfg7synahiZCZndRhxe_5lQRIEWEl34RFTRlbb6ic2iWqA6U1P6-yUq5HTCQSkHsCy2soOQofu_d5BOBcjcfDkRexr3oVpOWXHRvg5hi1yYk-f68yLSFE0_DVPUAkKnLKwiqw&lib=M71eeY3c397ix0pWSkIKAFphrWKM1Sp5a";
/** 2) Sample options (edit freely) */
const ORGS = [
  {
    name: "Mada Association",
    departments: [
      { name: "HR", projects: ["Enumerator Recruitment", "CFP Onboarding"] },
      { name: "Procurement", projects: ["Vouchers Market", "Local Tenders"] },
      { name: "Finance", projects: ["Cash for Work", "Monthly Reporting"] },
    ],
  },
  {
    name: "Nation Station",
    departments: [
      { name: "Operations", projects: ["Community Kitchen", "Warehouse"] },
      { name: "MEAL", projects: ["Post Distribution Monitoring", "Feedback Loop"] },
    ],
  },
];

function Section({ title, children }) {
  return (
    <div className="space-y-2">
      <label className="block text-sm font-medium text-slate-300">{title}</label>
      {children}
    </div>
  );
}

function TextInput(props) {
  return (
    <input
      {...props}
      className={
        "w-full rounded-md px-3 py-2 bg-slate-700/50 border border-slate-600 text-white " +
        "placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 " +
        (props.className || "")
      }
    />
  );
}

function Select({ value, onChange, options, placeholder = "Select…" }) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="w-full rounded-md px-3 py-2 bg-slate-700/50 border border-slate-600 text-white focus:outline-none focus:ring-2 focus:ring-teal-500"
    >
      <option value="">{placeholder}</option>
      {options.map((opt) => (
        <option key={opt} value={opt}>
          {opt}
        </option>
      ))}
    </select>
  );
}

function WelcomePage({ onGetStarted }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center p-4">
      <div className="max-w-4xl w-full grid lg:grid-cols-2 gap-8 items-center">
        <div className="space-y-8">
          <div className="space-y-6">
            <img
              src="/clickapp_wordmark_ink.svg"
              alt="Click’App"
              className="h-16 w-auto"
              onError={(e) => (e.currentTarget.style.display = "none")}
            />
            <div className="space-y-4">
              <h1 className="text-4xl lg:text-5xl font-bold text-slate-900 leading-tight">
                Welcome to the Future of{" "}
                <span className="text-transparent bg-gradient-to-r from-teal-600 to-orange-500 bg-clip-text">
                  Digital Innovation
                </span>
              </h1>
              <p className="text-xl text-slate-600">
                Transform your workflow with intelligent automation and seamless user experiences.
                Click’App helps NGOs and teams streamline approvals, recruitment, procurement, and more.
              </p>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-4">
            <button
              onClick={onGetStarted}
              className="inline-flex items-center justify-center rounded-lg bg-teal-600 hover:bg-teal-700 text-white px-8 py-3 text-lg"
            >
              Get Started
              <svg className="ml-2 h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M5 12h14" />
                <path d="M12 5l7 7-7 7" />
              </svg>
            </button>

            <a
              href="#"
              className="inline-flex items-center justify-center rounded-lg border border-slate-300 text-slate-700 hover:bg-slate-50 px-8 py-3 text-lg"
            >
              Watch Demo
            </a>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 pt-8">
            {[
              { title: "Secure", desc: "Enterprise-grade security" },
              { title: "Fast", desc: "Lightning-fast performance" },
              { title: "Intuitive", desc: "Easy to use interface" },
            ].map((f) => (
              <div key={f.title} className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-teal-100 rounded-full flex items-center justify-center">
                  <svg className="h-5 w-5 text-teal-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M20 6L9 17l-5-5" />
                  </svg>
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">{f.title}</h3>
                  <p className="text-sm text-slate-600">{f.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="relative">
          <div className="bg-white rounded-2xl shadow-2xl p-8 border border-slate-200">
            <div className="space-y-6">
              <div className="flex items-center justify-center">
                <div className="h-20 w-20 rounded-2xl bg-teal-600/10 flex items-center justify-center">
                  <svg className="h-10 w-10 text-teal-700" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2a10 10 0 100 20 10 10 0 000-20zm1 5v5h5v2h-7V7h2z" />
                  </svg>
                </div>
              </div>
              <div className="text-center space-y-2">
                <h3 className="text-xl font-semibold text-slate-900">Ready to begin?</h3>
                <p className="text-slate-600">Set up your account in just a few steps</p>
              </div>
              <div className="w-full h-2 bg-slate-200 rounded">
                <div className="h-2 bg-teal-600 rounded" style={{ width: "0%" }} />
              </div>
              <div className="text-center">
                <p className="text-sm text-slate-500">Step 0 of 3</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function RegistrationPage({ formData, handleInputChange, showPassword, setShowPassword, onNext, onBack }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <img
            src="/clickapp_wordmark_white.svg"
            alt="Click’App"
            className="h-12 w-auto mx-auto mb-6"
            onError={(e) => (e.currentTarget.style.display = "none")}
          />
          <h1 className="text-2xl font-bold text-white mb-2">Create Your Account</h1>
          <p className="text-slate-400">Join the Click’App community today</p>
        </div>

        <div className="mb-8">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-slate-400">Step 1 of 3</span>
            <span className="text-sm text-slate-400">33%</span>
          </div>
          <div className="w-full h-2 bg-slate-700 rounded">
            <div className="h-2 bg-teal-500 rounded" style={{ width: "33%" }} />
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 backdrop-blur-sm rounded-xl p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Section title="First Name">
              <TextInput
                id="firstName"
                placeholder="John"
                value={formData.firstName}
                onChange={(e) => handleInputChange("firstName", e.target.value)}
              />
            </Section>
            <Section title="Last Name">
              <TextInput
                id="lastName"
                placeholder="Doe"
                value={formData.lastName}
                onChange={(e) => handleInputChange("lastName", e.target.value)}
              />
            </Section>
          </div>

          <Section title="Email Address">
            <TextInput
              id="email"
              type="email"
              placeholder="john.doe@example.com"
              value={formData.email}
              onChange={(e) => handleInputChange("email", e.target.value)}
            />
          </Section>

          <Section title="Password">
            <div className="relative">
              <TextInput
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Create a strong password"
                value={formData.password}
                onChange={(e) => handleInputChange("password", e.target.value)}
                className="pr-10"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-300"
              >
                {showPassword ? "🙈" : "👁️"}
              </button>
            </div>
          </Section>

          <div className="flex flex-col space-y-4 pt-4">
            <button
              onClick={onNext}
              className="w-full inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white px-6 py-3"
            >
              Continue
              <svg className="ml-2 h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M5 12h14" />
                <path d="M12 5l7 7-7 7" />
              </svg>
            </button>

            <button
              onClick={onBack}
              className="w-full rounded-lg text-slate-300 hover:text-white hover:bg-slate-700/50 px-6 py-3 border border-transparent"
            >
              Back to Welcome
            </button>
          </div>

          <div className="text-center pt-4">
            <p className="text-sm text-slate-400">
              Already have an account? <a href="#" className="text-teal-400 hover:text-teal-300 font-medium">Sign in</a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

function OrgDeptProject({ formData, handleInputChange, onNext, onBack }) {
  const orgNames = useMemo(() => ORGS.map((o) => o.name), []);
  const departments = useMemo(() => {
    const o = ORGS.find((x) => x.name === formData.organization);
    return o ? o.departments.map((d) => d.name) : [];
  }, [formData.organization]);
  const projects = useMemo(() => {
    const o = ORGS.find((x) => x.name === formData.organization);
    const d = o?.departments.find((x) => x.name === formData.department);
    return d ? d.projects : [];
  }, [formData.organization, formData.department]);

  // Reset child fields if parent changes
  const setOrg = (v) => {
    handleInputChange("organization", v);
    handleInputChange("department", "");
    handleInputChange("project", "");
  };
  const setDept = (v) => {
    handleInputChange("department", v);
    handleInputChange("project", "");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-white mb-2">Organization Details</h1>
          <p className="text-slate-400">Choose your Organization → Department → Project</p>
        </div>

        <div className="mb-8">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-slate-400">Step 2 of 3</span>
            <span className="text-sm text-slate-400">66%</span>
          </div>
          <div className="w-full h-2 bg-slate-700 rounded">
            <div className="h-2 bg-teal-500 rounded" style={{ width: "66%" }} />
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 backdrop-blur-sm rounded-xl p-6 space-y-4">
          <Section title="Organization">
            <Select value={formData.organization} onChange={setOrg} options={orgNames} placeholder="Select organization…" />
          </Section>

          <Section title="Department">
            <Select value={formData.department} onChange={setDept} options={departments} placeholder="Select department…" />
          </Section>

          <Section title="Project">
            <Select value={formData.project} onChange={(v) => handleInputChange("project", v)} options={projects} placeholder="Select project…" />
          </Section>

          <div className="flex flex-col space-y-4 pt-2">
            <button
              onClick={onNext}
              className="w-full inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white px-6 py-3"
              disabled={!formData.organization || !formData.department || !formData.project}
            >
              Continue
            </button>

            <button
              onClick={onBack}
              className="w-full rounded-lg text-slate-300 hover:text-white hover:bg-slate-700/50 px-6 py-3 border border-transparent"
            >
              Back
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function ReviewSubmit({ formData, onBackToOrg, onSubmitted }) {
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  const payload = {
    step: "registration",
    firstName: formData.firstName,
    lastName: formData.lastName,
    email: formData.email,
    organization: formData.organization,
    department: formData.department,
    project: formData.project,
  };
  const canSubmit =
    payload.firstName &&
    payload.lastName &&
    payload.email &&
    payload.organization &&
    payload.department &&
    payload.project;

  async function submit() {
    setErr("");
    setLoading(true);
    try {
      // 1) Try a truly simple POST (no headers at all)
      try {
        const res = await fetch(ENDPOINT_URL, {
          method: "POST",
          body: JSON.stringify({ ...payload, token: "whenwewereinour30swewenttowar" }),
        });
        if (res.ok) {
          const data = await res.json().catch(() => ({}));
          if (data.ok) {
            onSubmitted();
            return;
          }
        }
      } catch {
        // ignore and fall through
      }

      // 2) Fallback: opaque request bypassing CORS
      try {
        await fetch(ENDPOINT_URL, {
          method: "POST",
          mode: "no-cors",
          body: JSON.stringify({ ...payload, token: "whenwewereinour30swewenttowar" }),
        });
        onSubmitted();
        return;
      } catch {
        // ignore and try beacon
      }

      // 3) Last resort: background beacon (fire-and-forget)
      try {
        const blob = new Blob(
          [JSON.stringify({ ...payload, token: "whenwewereinour30swewenttowar" })],
          { type: "text/plain" }
        );
        const sent = navigator.sendBeacon?.(ENDPOINT_URL, blob);
        if (sent) {
          onSubmitted();
          return;
        }
      } catch {}

      // If all three paths failed hard:
      throw new Error("network");
    } catch {
      setErr("Failed to fetch");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-white mb-2">Review & Submit</h1>
          <p className="text-slate-400">Confirm your details before sending</p>
        </div>

        <div className="mb-8">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-slate-400">Step 3 of 3</span>
            <span className="text-sm text-slate-400">100%</span>
          </div>
          <div className="w-full h-2 bg-slate-700 rounded">
            <div className="h-2 bg-teal-500 rounded" style={{ width: "100%" }} />
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 backdrop-blur-sm rounded-xl p-6 space-y-3 text-slate-200">
          <div className="flex justify-between"><span>Name</span><span>{payload.firstName} {payload.lastName}</span></div>
          <div className="flex justify-between"><span>Email</span><span>{payload.email}</span></div>
          <div className="flex justify-between"><span>Organization</span><span>{payload.organization}</span></div>
          <div className="flex justify-between"><span>Department</span><span>{payload.department}</span></div>
          <div className="flex justify-between"><span>Project</span><span>{payload.project}</span></div>

          {err && <p className="text-red-400 pt-2">{err}</p>}

          <div className="flex flex-col space-y-3 pt-4">
            <button
              onClick={submit}
              disabled={loading || !canSubmit}
              className="w-full inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white px-6 py-3 disabled:opacity-60"
            >
              {loading ? "Submitting…" : "Submit"}
            </button>
            <button
              onClick={onBackToOrg}
              className="w-full rounded-lg text-slate-300 hover:text-white hover:bg-slate-700/50 px-6 py-3 border border-transparent"
            >
              Back
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function Success() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-white border border-slate-200 rounded-2xl p-8 text-center shadow-xl">
        <div className="mx-auto mb-4 w-12 h-12 rounded-full bg-teal-600/10 flex items-center justify-center">
          <svg className="h-6 w-6 text-teal-700" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 6L9 17l-5-5"/></svg>
        </div>
        <h2 className="text-2xl font-semibold text-slate-900">Submitted!</h2>
        <p className="text-slate-600 mt-2">We received your request. You’ll get a confirmation email shortly.</p>
      </div>
    </div>
  );
}

export default function App() {
  const [step, setStep] = useState("welcome");
  const [showPassword, setShowPassword] = useState(false);
  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    email: "",
    password: "",
    organization: "",
    department: "",
    project: "",
  });

  const handle = (field, value) => setForm((p) => ({ ...p, [field]: value }));

  return (
    <div className="font-sans">
      {step === "welcome" && <WelcomePage onGetStarted={() => setStep("reg")} />}
      {step === "reg" && (
        <RegistrationPage
          formData={form}
          handleInputChange={handle}
          showPassword={showPassword}
          setShowPassword={setShowPassword}
          onNext={() => setStep("odp")}
          onBack={() => setStep("welcome")}
        />
      )}
      {step === "odp" && (
        <OrgDeptProject
          formData={form}
          handleInputChange={handle}
          onNext={() => setStep("review")}
          onBack={() => setStep("reg")}
        />
      )}
      {step === "review" && (
        <ReviewSubmit
          formData={form}
          onBackToOrg={() => setStep("odp")}
          onSubmitted={() => setStep("done")}
        />
      )}
      {step === "done" && <Success />}
    </div>
  );
}